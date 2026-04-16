package com.example.guardian

import android.Manifest
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.example.guardian.admin.GuardianDeviceAdmin
import com.example.guardian.vpn.GuardianVpnService

class MainActivity : FlutterActivity() {

    private val CHANNEL = "guardian/protection"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    // ==================== ADMIN ====================
                    "activateDeviceAdmin" -> {
                        activateDeviceAdmin()
                        result.success(null)
                    }

                    "isDeviceAdminActive" -> {
                        result.success(isAdminActive())
                    }

                    // ==================== VPN ====================
                    "startVpn" -> {
                        val intent = android.net.VpnService.prepare(this)

                        if (intent != null) {
                            startActivityForResult(intent, 1001)
                            result.success(false)
                        } else {
                            startVpnService()
                            result.success(true)
                        }
                    }

                    "stopVpn" -> {
                        stopService(Intent(this, GuardianVpnService::class.java))
                        result.success(true)
                    }

                    "isVpnRunning" -> {
                        val manager = getSystemService(Context.CONNECTIVITY_SERVICE) as android.net.ConnectivityManager
                        val networks = manager.allNetworks

                        var isVpnActive = false

                        for (network in networks) {
                            val caps = manager.getNetworkCapabilities(network)
                            if (caps?.hasTransport(android.net.NetworkCapabilities.TRANSPORT_VPN) == true) {
                                isVpnActive = true
                                break
                            }
                        }

                        result.success(isVpnActive)
                    }

                    // ==================== ACCESSIBILITY ====================
                    "isAccessibilityEnabled" -> {
                        result.success(isAccessibilityEnabled())
                    }

                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }

                    "openVpnSettings" -> {
                        startActivity(Intent(Settings.ACTION_VPN_SETTINGS))
                        result.success(null)
                    }

                    // ==================== CALL ====================
                    "callNumber" -> {
                        val phone = call.argument<String>("phone") ?: ""
                        handleCall(phone)
                        result.success(true)
                    }

                    // ==================== SMS ====================
                    "smsNumber" -> {
                        val phone = call.argument<String>("phone") ?: ""
                        val message = call.argument<String>("message") ?: ""
                        handleSms(phone, message)
                        result.success(true)
                    }

                    // ==================== OTHER ====================
                    "getBlockAttemptCount" -> {
                        result.success(0)
                    }

                    "verifyPassword" -> {
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ==================== CALL HANDLER ====================
    private fun handleCall(phone: String) {
        if (phone.isEmpty()) return

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CALL_PHONE),
                2001
            )
            return
        }

        val intent = Intent(Intent.ACTION_CALL)
        intent.data = Uri.parse("tel:$phone")
        startActivity(intent)
    }

    // ==================== SMS HANDLER ====================
    private fun handleSms(phone: String, message: String) {
        if (phone.isEmpty()) return

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.SEND_SMS),
                2002
            )
            return
        }

        val intent = Intent(Intent.ACTION_SENDTO)
        intent.data = Uri.parse("smsto:$phone")
        intent.putExtra("sms_body", message)
        startActivity(intent)
    }

    // ==================== ADMIN ====================
    private fun activateDeviceAdmin() {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(
            DevicePolicyManager.EXTRA_DEVICE_ADMIN,
            ComponentName(this, GuardianDeviceAdmin::class.java)
        )
        startActivity(intent)
    }

    private fun isAdminActive(): Boolean {
        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        return dpm.isAdminActive(ComponentName(this, GuardianDeviceAdmin::class.java))
    }

    // ==================== ACCESSIBILITY ====================
    private fun isAccessibilityEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabled?.contains(packageName) == true
    }

    // ==================== VPN ====================
    private fun startVpnService() {
        val intent = Intent(this, GuardianVpnService::class.java)
        intent.action = GuardianVpnService.ACTION_START
        ContextCompat.startForegroundService(this, intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == 1001 && resultCode == RESULT_OK) {
            startVpnService()
        }
    }
}