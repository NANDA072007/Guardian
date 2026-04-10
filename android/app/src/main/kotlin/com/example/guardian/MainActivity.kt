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

class MainActivity: FlutterActivity() {

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
                        val intent = Intent(this, GuardianVpnService::class.java)
                        intent.action = GuardianVpnService.ACTION_START
                        startService(intent)
                        result.success(false)
                    }

                    "stopVpn" -> {
                        stopService(Intent(this, GuardianVpnService::class.java))
                        result.success(true)
                    }

                    "isVpnRunning" -> {
                        result.success(GuardianVpnService.isRunning)
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
}