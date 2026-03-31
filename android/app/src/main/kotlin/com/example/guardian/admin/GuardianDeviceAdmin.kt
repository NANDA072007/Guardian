// android/app/src/main/kotlin/com/example/guardian/admin/GuardianDeviceAdmin.kt
// Unchanged from original — already correct
package com.example.guardian.admin

import android.app.admin.DeviceAdminReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.UserManager
import android.util.Log
import android.widget.Toast

class GuardianDeviceAdmin : DeviceAdminReceiver() {

    companion object {
        private const val TAG = "GuardianDeviceAdmin"
        const val EXTRA_FORCE_RECOVERY = "force_recovery_mode"
    }

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.i(TAG, "Device Admin ENABLED")
        Toast.makeText(context, "Guardian protection activated", Toast.LENGTH_SHORT).show()
        checkWorkProfile(context)
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        return """
⚠️ WARNING: You are about to disable Guardian

This will remove ALL protection immediately.

To proceed safely:
→ Contact your trusted person
→ Get the password

If you continue without it:
→ Guardian will enter recovery mode
""".trimIndent()
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.e(TAG, "CRITICAL: Device Admin DISABLED")
        Toast.makeText(context, "Guardian protection disabled", Toast.LENGTH_LONG).show()
        triggerRecoveryMode(context)
    }

    private fun triggerRecoveryMode(context: Context) {
        try {
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName) ?: return

            launchIntent.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                putExtra(EXTRA_FORCE_RECOVERY, true)
            }

            context.startActivity(launchIntent)
            Log.i(TAG, "Recovery mode triggered")
        } catch (e: Exception) {
            Log.e(TAG, "Recovery trigger failed", e)
        }
    }

    fun isAdminActive(context: Context): Boolean {
        return try {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE)
                    as android.app.admin.DevicePolicyManager
            val component = ComponentName(context, GuardianDeviceAdmin::class.java)
            dpm.isAdminActive(component)
        } catch (e: Exception) {
            Log.e(TAG, "Admin check failed", e)
            false
        }
    }

    private fun checkWorkProfile(context: Context) {
        try {
            val um = context.getSystemService(Context.USER_SERVICE) as UserManager
            if (um.isManagedProfile) {
                Log.w(TAG, "Running inside WORK PROFILE — protection may be limited")
                Toast.makeText(
                    context,
                    "Warning: Work profile detected. Some protection may be limited.",
                    Toast.LENGTH_LONG
                ).show()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Work profile check failed", e)
        }
    }
}
