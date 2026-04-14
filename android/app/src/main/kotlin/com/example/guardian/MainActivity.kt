package com.example.guardian

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Settings
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
                    "activateDeviceAdmin" -> {
                        activateDeviceAdmin()
                        result.success(null)
                    }

                    "isDeviceAdminActive" -> {
                        result.success(isAdminActive())
                    }

                    "startVpn" -> {
                        val intent = android.net.VpnService.prepare(this)

                        if (intent != null) {
                            // User has NOT granted permission yet → show system popup
                            startActivityForResult(intent, 1001)
                            result.success(false)
                        } else {
                            // Permission already granted → start VPN directly
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

    private fun isAccessibilityEnabled(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        )
        return enabled?.contains(packageName) == true
    }
    private fun startVpnService() {
        val intent = Intent(this, GuardianVpnService::class.java)
        intent.action = GuardianVpnService.ACTION_START
        androidx.core.content.ContextCompat.startForegroundService(this, intent)

    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == 1001) {
            if (resultCode == RESULT_OK) {
                startVpnService()
            }
        }
    }
}