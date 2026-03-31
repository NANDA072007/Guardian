// android/app/src/main/kotlin/com/example/guardian/ml/ScreenAnalyzer.kt
// No changes from original — this is correct
package com.example.guardian.ml

import android.content.Context
import android.content.Intent
import android.os.PowerManager
import androidx.core.content.ContextCompat
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

class ScreenAnalyzerWorker(
    private val context: Context,
    params: WorkerParameters
) : CoroutineWorker(context, params) {

    override suspend fun doWork(): Result {
        // Only analyze when screen is on
        if (!isScreenOn()) return Result.success()

        val intent = Intent(context, ScreenCaptureService::class.java)
        ContextCompat.startForegroundService(context, intent)

        return Result.success()
    }

    private fun isScreenOn(): Boolean {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isInteractive
    }
}

// ─────────────────────────────────────────────────────────────────────────────

// android/app/src/main/kotlin/com/example/guardian/ml/ScreenAnalyzerScheduler.kt
// No changes from original — this is correct
// (Put in same file for brevity, or split into ScreenAnalyzerScheduler.kt)
