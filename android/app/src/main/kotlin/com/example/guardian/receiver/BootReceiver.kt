// android/app/src/main/kotlin/com/example/guardian/receiver/BootReceiver.kt
// Unchanged from original — already correct
package com.example.guardian.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import com.example.guardian.vpn.GuardianVpnService
import com.example.guardian.ml.ScreenAnalyzerScheduler

class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "GuardianBootReceiver"
    }

    override fun onReceive(context: Co   ntext?, intent: Intent?) {
        if (context == null || intent == null) {
            Log.e(TAG, "Boot: null context or intent")
            return
        }

        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.i(TAG, "Boot event: ${intent.action}")
                startVpn(context)
                scheduleScreenAnalyzer(context)
            }
            else -> Log.w(TAG, "Ignored action: ${intent.action}")
        }
    }

    private fun startVpn(context: Context) {
        try {
            val intent = Intent(context, GuardianVpnService::class.java).apply {
                action = GuardianVpnService.ACTION_START
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ContextCompat.startForegroundService(context, intent)
            } else {
                context.startService(intent)
            }
            Log.i(TAG, "VPN start requested on boot")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start VPN on boot", e)
        }
    }

    private fun scheduleScreenAnalyzer(context: Context) {
        try {
            ScreenAnalyzerScheduler.schedule(context)
            Log.i(TAG, "ScreenAnalyzer scheduled on boot")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to schedule ScreenAnalyzer on boot", e)
        }
    }
}
