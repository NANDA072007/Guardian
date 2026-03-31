// android/app/src/main/kotlin/com/example/guardian/vpn/GuardianVpnService.kt
package com.example.guardian.vpn

import android.app.*
import android.content.Intent
import android.net.VpnService
import android.os.*
import android.system.OsConstants
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import com.example.guardian.db.GuardianDatabase
import kotlinx.coroutines.*
import java.io.FileInputStream
import java.io.FileOutputStream
import java.net.*
import java.util.concurrent.ConcurrentHashMap

class GuardianVpnService : VpnService() {

    companion object {
        const val ACTION_START = "com.example.guardian.vpn.ACTION_START"
        const val ACTION_STOP  = "com.example.guardian.vpn.ACTION_STOP"
        private const val TAG = "GuardianVPN"
        private const val NOTIFICATION_ID  = 1001
        private const val CHANNEL_ID = "guardian_vpn"
    }

    private var vpnInterface: ParcelFileDescriptor? = null
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    // Preloaded blocklist: ConcurrentHashMap for thread-safe reads from VPN loop
    private val blockedSet = ConcurrentHashMap<String, Boolean>(150_000)

    // FIX: Reuse a single protected DNS socket instead of creating one per query
    private var dnsSocket: DatagramSocket? = null
    private val DNS_UPSTREAM = "1.1.1.3"   // Cloudflare Family
    private val DNS_FALLBACK  = "1.0.0.3"  // Cloudflare Family backup

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startVpn()
            ACTION_STOP  -> stopVpn()
            // null intent = service restarted by OS via START_STICKY — resume
            null -> startVpn()
        }
        return START_STICKY
    }

    // FIX: onRevoke uses startForegroundService (required on Android 8+)
    // Old code used startService() which throws IllegalStateException from background
    override fun onRevoke() {
        super.onRevoke()
        Log.w(TAG, "VPN revoked — scheduling restart")
        closeVpnInterface()

        Handler(Looper.getMainLooper()).postDelayed({
            val intent = Intent(this, GuardianVpnService::class.java).apply {
                action = ACTION_START
            }
            ContextCompat.startForegroundService(this, intent)
        }, 1000)
    }

    private fun startVpn() {
        if (vpnInterface != null) return

        // FIX: startForeground() MUST be called before establish() on Android 8+
        // Previously called AFTER establish() — could timeout and crash
        startForeground(NOTIFICATION_ID, createNotification())

        val builder = Builder()
            .setSession("Guardian VPN")
            .setMtu(1500)
            .addAddress("10.0.0.2", 32)
            .addDnsServer("1.1.1.3")
            .addDnsServer("1.0.0.3")
            .addRoute("0.0.0.0", 0)

        if (Build.VERSION.SDK_INT >= 29) {
            builder.allowFamily(OsConstants.AF_INET)
            builder.allowFamily(OsConstants.AF_INET6)
            builder.addRoute("::", 0)
        }

        vpnInterface = builder.establish()

        if (vpnInterface == null) {
            Log.e(TAG, "VPN establish() returned null")
            stopSelf()
            return
        }

        // FIX: Create single protected DNS socket — reused for all queries
        try {
            dnsSocket = DatagramSocket().also { socket ->
                if (!protect(socket)) {
                    socket.close()
                    dnsSocket = null
                    Log.e(TAG, "Failed to protect DNS socket — aborting VPN start")
                    stopSelf()
                    return
                }
                socket.soTimeout = 2000
            }
        } catch (e: Exception) {
            Log.e(TAG, "DNS socket creation failed", e)
            stopSelf()
            return
        }

        scope.launch {
            preloadBlocklist()
            runVpnLoop()
        }
    }

    private fun stopVpn() {
        scope.cancel()
        dnsSocket?.close()
        dnsSocket = null
        closeVpnInterface()
        stopForeground(true)
        stopSelf()
    }

    private fun closeVpnInterface() {
        try { vpnInterface?.close() } catch (_: Exception) {}
        vpnInterface = null
    }

    private fun createNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Guardian Protection",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Guardian Active")
            .setContentText("All traffic protected")
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setOngoing(true)
            .build()
    }

    private suspend fun preloadBlocklist() {
        try {
            val dao = GuardianDatabase.getInstance(applicationContext).blockedDomainDao()
            val domains = dao.getAllDomains()

            domains.forEach { domain ->
                blockedSet[domain.trim().lowercase()] = true
            }

            Log.i(TAG, "Blocklist loaded: ${blockedSet.size} domains")

            // FIX: If blocklist is empty, we give false sense of protection.
            // Stop the VPN rather than run unprotected.
            if (blockedSet.isEmpty()) {
                Log.e(TAG, "Blocklist is EMPTY — refusing to run VPN without protection data")
                withContext(Dispatchers.Main) { stopSelf() }
            }

        } catch (e: Exception) {
            Log.e(TAG, "Blocklist load failed", e)
        }
    }

    private suspend fun runVpnLoop() = withContext(Dispatchers.IO) {
        val input  = FileInputStream(vpnInterface!!.fileDescriptor)
        val output = FileOutputStream(vpnInterface!!.fileDescriptor)
        val buffer = ByteArray(32767)

        while (isActive) {
            try {
                val length = input.read(buffer)
                if (length <= 0) continue

                // FIX: Parse DNS correctly from IP packet structure
                // Old code parsed from offset 12 (inside IP header — wrong)
                // Correct: IP(20) + UDP(8) = offset 28 for DNS payload
                val domain = parseDnsFromIpPacket(buffer, length)

                if (domain == null) {
                    // Not a DNS query — forward as-is
                    output.write(buffer, 0, length)
                    continue
                }

                if (isBlocked(domain)) {
                    Log.w(TAG, "BLOCKED: $domain")
                    output.write(buildNxDomainResponse(buffer, length))
                    continue
                }

                // Forward to upstream DNS
                forwardDnsQuery(buffer, length, output)

            } catch (e: Exception) {
                if (isActive) Log.e(TAG, "VPN loop error", e)
            }
        }
    }

    // FIX: Correct IP packet parsing
    // Structure: IPv4 header(20 bytes) + UDP header(8 bytes) + DNS payload
    // DNS answer starts at byte 28, domain labels start at byte 28+12=40
    private fun parseDnsFromIpPacket(packet: ByteArray, length: Int): String? {
        if (length < 40) return null  // too small to be a valid DNS query in UDP in IP

        // Check IP protocol (byte 9) = 17 means UDP
        if (packet[9].toInt() and 0xFF != 17) return null

        // Check destination port (bytes 22-23) = 53 means DNS
        val destPort = ((packet[22].toInt() and 0xFF) shl 8) or (packet[23].toInt() and 0xFF)
        if (destPort != 53) return null

        // DNS payload starts at byte 28, question section starts at byte 28+12=40
        val dnsStart = 28
        var i = dnsStart + 12  // skip 12-byte DNS header

        if (i >= length) return null

        val sb = StringBuilder()
        while (i < length) {
            val labelLen = packet[i].toInt() and 0xFF
            if (labelLen == 0) break
            i++
            if (i + labelLen > length) return null
            sb.append(String(packet, i, labelLen, Charsets.US_ASCII))
            sb.append(".")
            i += labelLen
        }

        return if (sb.isEmpty()) null else sb.toString().dropLast(1).lowercase()
    }

    private fun isBlocked(domain: String): Boolean {
        if (blockedSet.containsKey(domain)) return true
        // Check parent domains (e.g. "sub.pornhub.com" → "pornhub.com")
        val parts = domain.split(".")
        for (i in 1 until parts.size - 1) {
            val parent = parts.subList(i, parts.size).joinToString(".")
            if (blockedSet.containsKey(parent)) return true
        }
        return false
    }

    // Returns NXDOMAIN response for blocked domain
    private fun buildNxDomainResponse(query: ByteArray, length: Int): ByteArray {
        val response = query.copyOf(length)
        // Byte 28+2 = flags high byte: QR=1 (response), Opcode=0, AA=0, TC=0, RD=1
        // Byte 28+3 = flags low byte: RA=1, Z=0, RCODE=3 (NXDOMAIN)
        if (length > 31) {
            response[30] = 0x81.toByte()
            response[31] = 0x83.toByte()
        }
        return response
    }

    // FIX: Reuse the single dnsSocket instead of creating new one per query
    private fun forwardDnsQuery(buffer: ByteArray, length: Int, output: FileOutputStream) {
        val socket = dnsSocket ?: return
        try {
            synchronized(socket) {
                val upstream = InetAddress.getByName(DNS_UPSTREAM)
                socket.send(DatagramPacket(buffer, length, upstream, 53))

                val respBuffer = ByteArray(32767)
                val respPacket = DatagramPacket(respBuffer, respBuffer.size)
                socket.receive(respPacket)

                output.write(respPacket.data, 0, respPacket.length)
            }
        } catch (e: Exception) {
            Log.e(TAG, "DNS forward error: ${e.message}")
            // Try fallback DNS
            try {
                synchronized(socket) {
                    val fallback = InetAddress.getByName(DNS_FALLBACK)
                    socket.send(DatagramPacket(buffer, length, fallback, 53))
                    val fb = ByteArray(32767)
                    val fbPacket = DatagramPacket(fb, fb.size)
                    socket.receive(fbPacket)
                    output.write(fbPacket.data, 0, fbPacket.length)
                }
            } catch (fe: Exception) {
                Log.e(TAG, "DNS fallback also failed", fe)
            }
        }
    }
}
