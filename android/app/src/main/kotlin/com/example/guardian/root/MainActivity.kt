// android/app/src/main/kotlin/com/example/guardian/MainActivity.kt
package com.example.guardian

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import android.view.WindowManager
import androidx.core.content.ContextCompat
import com.example.guardian.accessibility.GuardianAccessibilityService
import com.example.guardian.admin.GuardianDeviceAdmin
import com.example.guardian.db.GuardianDatabase
import com.example.guardian.ml.MediaProjectionHolder
import com.example.guardian.ml.ScreenAnalyzerScheduler
import com.example.guardian.vpn.GuardianVpnService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    private val CHANNEL = "guardian/protection"
    private val TAG = "GuardianMain"
    private val executor = Executors.newSingleThreadExecutor()

    private lateinit var projectionManager: MediaProjectionManager
    private val REQUEST_CAPTURE = 999

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        projectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
    }

    // Called from Enable VPN screen or anywhere that needs screen capture
    fun requestScreenCapture() {
        try {
            val intent = projectionManager.createScreenCaptureIntent()
            startActivityForResult(intent, REQUEST_CAPTURE)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to request screen capture", e)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CAPTURE && resultCode == Activity.RESULT_OK && data != null) {
            try {
                MediaProjectionHolder.projection = projectionManager.getMediaProjection(resultCode, data)
                // Start the screen analyzer now that we have permission
                ScreenAnalyzerScheduler.schedule(applicationContext)
                Log.i(TAG, "MediaProjection initialized + ScreenAnalyzer scheduled")
            } catch (e: Exception) {
                Log.e(TAG, "MediaProjection setup failed", e)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {

                        // ==================== PASSWORD ====================
                        // FIX: password hash is passed FROM Dart (where flutter_secure_storage
                        // is accessible) rather than reading SharedPreferences directly from
                        // Kotlin (which reads unencrypted keys and always returns null).
                        "verifyPassword" -> {
                            val input = call.argument<String>("password")
                            val storedHash = call.argument<String>("storedHash")

                            if (input.isNullOrBlank() || storedHash.isNullOrBlank()) {
                                result.error("INVALID_INPUT", "password or storedHash missing", null)
                                return@setMethodCallHandler
                            }

                            result.success(sha256(input) == storedHash)
                        }

                        // ==================== DEVICE ADMIN ====================
                        "activateDeviceAdmin" -> {
                            val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                                putExtra(
                                    DevicePolicyManager.EXTRA_DEVICE_ADMIN,
                                    ComponentName(this@MainActivity, GuardianDeviceAdmin::class.java)
                                )
                                putExtra(
                                    DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                                    "Guardian needs Device Admin to prevent uninstall without your trusted person's password."
                                )
                            }
                            startActivity(intent)
                            result.success(true)
                        }

                        "isDeviceAdminActive" -> {
                            val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                            val component = ComponentName(this, GuardianDeviceAdmin::class.java)
                            result.success(dpm.isAdminActive(component))
                        }

                        // ==================== VPN ====================
                        "startVpn" -> {
                            val prepareIntent = VpnService.prepare(this)
                            if (prepareIntent != null) {
                                // Permission not granted yet — show system dialog
                                startActivityForResult(prepareIntent, 0)
                                result.success(false) // false = permission dialog shown
                                return@setMethodCallHandler
                            }

                            val intent = Intent(this, GuardianVpnService::class.java).apply {
                                action = GuardianVpnService.ACTION_START
                            }
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                ContextCompat.startForegroundService(this, intent)
                            } else {
                                startService(intent)
                            }
                            result.success(true) // true = started
                        }

                        "stopVpn" -> {
                            // Password verification done on Dart side before calling this
                            val intent = Intent(this, GuardianVpnService::class.java).apply {
                                action = GuardianVpnService.ACTION_STOP
                            }
                            startService(intent)
                            result.success(true)
                        }

                        "isVpnRunning" -> {
                            result.success(isVpnActive())
                        }

                        "openVpnSettings" -> {
                            startActivity(Intent(Settings.ACTION_VPN_SETTINGS))
                            result.success(true)
                        }

                        // ==================== ACCESSIBILITY ====================
                        "isAccessibilityEnabled" -> {
                            result.success(isAccessibilityEnabled())
                        }

                        "openAccessibilitySettings" -> {
                            startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                            result.success(true)
                        }

                        // ==================== DATABASE ====================
                        "getBlockAttemptCount" -> {
                            executor.execute {
                                try {
                                    val db = GuardianDatabase.getInstance(applicationContext)
                                    val count = db.blockAttemptDao().getTotalCountSync()
                                    runOnUiThread { result.success(count) }
                                } catch (e: Exception) {
                                    runOnUiThread { result.error("DB_ERROR", e.message, null) }
                                }
                            }
                        }

                        // ==================== MEDIA PROJECTION (Layer 3) ====================
                        "requestScreenCapture" -> {
                            requestScreenCapture()
                            result.success(true)
                        }

                        // ==================== SECURITY ====================
                        // FLAG_SECURE prevents screenshots — used on password handoff screen
                        "setWindowSecure" -> {
                            val secure = call.argument<Boolean>("secure") ?: true
                            if (secure) {
                                window.setFlags(
                                    WindowManager.LayoutParams.FLAG_SECURE,
                                    WindowManager.LayoutParams.FLAG_SECURE
                                )
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            }
                            result.success(null)
                        }

                        // ==================== EMERGENCY ====================
                        "callNumber" -> {
                            val phone = call.argument<String>("phone") ?: ""
                            if (phone.isBlank()) {
                                result.error("INVALID_PHONE", "Phone number is empty", null)
                                return@setMethodCallHandler
                            }
                            val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$phone"))
                            startActivity(intent)
                            result.success(true)
                        }

                        "smsNumber" -> {
                            val phone = call.argument<String>("phone") ?: ""
                            val msg = call.argument<String>("message") ?: "I need help. Please reach out."
                            if (phone.isBlank()) {
                                result.error("INVALID_PHONE", "Phone number is empty", null)
                                return@setMethodCallHandler
                            }
                            val uri = Uri.parse("smsto:$phone")
                            val intent = Intent(Intent.ACTION_SENDTO, uri).apply {
                                putExtra("sms_body", msg)
                            }
                            startActivity(intent)
                            result.success(true)
                        }

                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("FATAL_ERROR", e.message, null)
                }
            }
    }

    // ==================== HELPERS ====================

    private fun isVpnActive(): Boolean {
        return try {
            val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val network = cm.activeNetwork ?: return false
            val caps = cm.getNetworkCapabilities(network) ?: return false
            caps.hasTransport(NetworkCapabilities.TRANSPORT_VPN)
        } catch (e: Exception) {
            Log.e(TAG, "VPN check failed", e)
            false
        }
    }

    private fun isAccessibilityEnabled(): Boolean {
        return try {
            val expected = "$packageName/${GuardianAccessibilityService::class.java.name}"
            val enabled = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false

            val splitter = TextUtils.SimpleStringSplitter(':')
            splitter.setString(enabled)
            while (splitter.hasNext()) {
                if (splitter.next().equals(expected, ignoreCase = true)) return true
            }
            false
        } catch (e: Exception) {
            Log.e(TAG, "Accessibility check failed", e)
            false
        }
    }

    private fun sha256(input: String): String {
        val bytes = MessageDigest.getInstance("SHA-256")
            .digest(input.toByteArray(Charsets.UTF_8))
        return bytes.joinToString("") { "%02x".format(it) }
    }
}
