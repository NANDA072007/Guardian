package com.example.guardian.vpn

import android.app.*
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class GuardianVpnService : VpnService() {

    companion object {
        const val ACTION_START = "com.example.guardian.vpn.ACTION_START"
        const val ACTION_STOP  = "com.example.guardian.vpn.ACTION_STOP"

        private const val NOTIFICATION_ID = 1001
        private const val CHANNEL_ID = "guardian_vpn"

        @Volatile
        var isRunning: Boolean = false
    }

    private var vpnInterface: ParcelFileDescriptor? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startVpn()
            ACTION_STOP  -> stopVpn()
            null -> startVpn()
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onRevoke() {
        super.onRevoke()

        // Auto restart VPN
        val intent = Intent(this, GuardianVpnService::class.java).apply {
            action = ACTION_START
        }
        ContextCompat.startForegroundService(this, intent)
    }

    private fun startVpn() {
        if (vpnInterface != null) return

        isRunning = true

        startForeground(NOTIFICATION_ID, createNotification())

        val builder = Builder()
            .setSession("Guardian Protection")
            .addAddress("10.0.0.2", 32)

            // 🔥 FAST DNS FILTERING (NO LAG)
            .addDnsServer("1.1.1.3")   // Cloudflare Family (blocks adult)
            .addDnsServer("1.0.0.3")

            // Route all traffic through VPN
            .addRoute("0.0.0.0", 0)

        if (Build.VERSION.SDK_INT >= 29) {
            builder.addRoute("::", 0)
        }

        vpnInterface = builder.establish()
    }

    private fun stopVpn() {
        try {
            vpnInterface?.close()
        } catch (_: Exception) {}

        vpnInterface = null
        isRunning = false

        stopForeground(true)
        stopSelf()
    }

    private fun createNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Guardian Protection",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Guardian Active")
            .setContentText("Your internet is protected")
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setOngoing(true)
            .build()
    }
}