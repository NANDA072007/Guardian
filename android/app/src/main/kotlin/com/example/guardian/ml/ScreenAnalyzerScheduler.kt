// android/app/src/main/kotlin/com/example/guardian/ml/ScreenAnalyzerScheduler.kt
// Unchanged from original — already correct
package com.example.guardian.ml

import android.content.Context
import androidx.work.*
import java.util.concurrent.TimeUnit

object ScreenAnalyzerScheduler {

    private const val WORK_NAME = "guardian_screen_analysis"

    fun schedule(context: Context) {
        val request = PeriodicWorkRequestBuilder<ScreenAnalyzerWorker>(
            15, TimeUnit.MINUTES  // Android enforced minimum interval
        )
            .setConstraints(
                Constraints.Builder()
                    .setRequiresBatteryNotLow(false)
                    .setRequiresDeviceIdle(false)
                    .build()
            )
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,  // Don't restart if already scheduled
            request
        )
    }

    fun cancel(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(WORK_NAME)
    }
}
