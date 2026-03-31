// android/app/src/main/kotlin/com/example/guardian/ml/ScreenCaptureService.kt
package com.example.guardian.ml

import android.app.*
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.guardian.block.BlockOverlayActivity
import com.example.guardian.db.BlockAttemptEntity
import com.example.guardian.db.GuardianDatabase
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.label.ImageLabeler
import com.google.mlkit.vision.label.ImageLabeling
import com.google.mlkit.vision.label.defaults.ImageLabelerOptions
import kotlinx.coroutines.*
import kotlinx.coroutines.tasks.await
import java.nio.ByteBuffer

class ScreenCaptureService : Service() {

    companion object {
        private const val TAG = "ScreenCaptureService"
        private const val CHANNEL_ID = "guardian_ml_service"
        private const val NOTIFICATION_ID = 3001
        private const val ANALYSIS_INTERVAL_MS = 7_000L  // 7 seconds between captures
        private const val CONFIDENCE_THRESHOLD = 0.75f

        // FIX: Broader label set — ML Kit base labeler returns general objects.
        // "Swimwear"/"Underwear" alone miss nearly all explicit content.
        // This expanded set catches more signals while keeping false positives low.
        private val EXPLICIT_LABELS = setOf(
            "swimwear", "undergarment", "underwear", "lingerie",
            "bikini", "brassiere", "briefs", "nudity", "adult content",
            "barechestedness", "skin", "human body"
        )
        // High-confidence labels that alone are sufficient to block
        private val HIGH_CONFIDENCE_LABELS = setOf("nudity", "adult content")
        private const val HIGH_CONFIDENCE_THRESHOLD = 0.85f
    }

    private var projection = MediaProjectionHolder.projection
    private var job: Job? = null

    // FIX: Create labeler ONCE and reuse — was being created/destroyed every 7 seconds,
    // which reloads the ML model and leaks native resources
    private var labeler: ImageLabeler? = null

    override fun onCreate() {
        super.onCreate()
        startForeground(NOTIFICATION_ID, createNotification())

        // Initialize labeler once at service start
        labeler = ImageLabeling.getClient(
            ImageLabelerOptions.Builder()
                .setConfidenceThreshold(CONFIDENCE_THRESHOLD)
                .build()
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        projection = MediaProjectionHolder.projection

        if (projection == null) {
            Log.e(TAG, "MediaProjection is null — service cannot run")
            stopSelf()
            return START_NOT_STICKY
        }

        if (job == null || job?.isActive == false) {
            startAnalysisLoop()
        }

        return START_STICKY
    }

    private fun startAnalysisLoop() {
        job = CoroutineScope(Dispatchers.Default).launch {
            while (isActive) {
                try {
                    if (isScreenOn()) {
                        val bitmap = captureScreen()
                        if (bitmap != null) {
                            val isExplicit = analyze(bitmap)
                            bitmap.recycle()

                            if (isExplicit) {
                                logBlock()
                                launchOverlay()
                            }
                        }
                    }
                    delay(ANALYSIS_INTERVAL_MS)
                } catch (e: CancellationException) {
                    throw e  // Let coroutine cancel properly
                } catch (e: Exception) {
                    Log.e(TAG, "Analysis loop error", e)
                    delay(ANALYSIS_INTERVAL_MS)
                }
            }
        }
    }

    private fun isScreenOn(): Boolean {
        val pm = getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        return pm.isInteractive
    }

    private fun captureScreen(): Bitmap? {
        val p = projection ?: return null
        val metrics = resources.displayMetrics
        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi

        var reader: ImageReader? = null
        var display: VirtualDisplay? = null

        return try {
            reader = ImageReader.newInstance(width, height, android.graphics.PixelFormat.RGBA_8888, 2)
            display = p.createVirtualDisplay(
                "guardian_capture",
                width, height, density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                reader.surface, null, null
            )

            // Small delay to let the surface render
            Thread.sleep(100)

            val image = reader.acquireLatestImage() ?: return null

            val plane = image.planes[0]
            val buffer: ByteBuffer = plane.buffer
            val pixelStride = plane.pixelStride
            val rowStride = plane.rowStride
            val rowPadding = rowStride - pixelStride * width

            // FIX: The padded bitmap must be recycled after cropping.
            // Previous code created paddedBitmap → cropped → abandoned paddedBitmap (~8-16MB leak every 7s)
            val paddedBitmap = Bitmap.createBitmap(
                width + rowPadding / pixelStride,
                height,
                Bitmap.Config.ARGB_8888
            )
            paddedBitmap.copyPixelsFromBuffer(buffer)
            image.close()

            val cropped = Bitmap.createBitmap(paddedBitmap, 0, 0, width, height)
            paddedBitmap.recycle()  // FIX: Recycle the padded source immediately

            cropped

        } catch (e: Exception) {
            Log.e(TAG, "Screen capture failed", e)
            null
        } finally {
            display?.release()
            reader?.close()
        }
    }

    private suspend fun analyze(bitmap: Bitmap): Boolean {
        val l = labeler ?: return false

        // Scale down to 1/4 resolution for faster inference
        val scaledWidth = (bitmap.width / 4).coerceAtLeast(1)
        val scaledHeight = (bitmap.height / 4).coerceAtLeast(1)
        val scaled = Bitmap.createScaledBitmap(bitmap, scaledWidth, scaledHeight, true)

        return try {
            val image = InputImage.fromBitmap(scaled, 0)
            val labels = l.process(image).await()
            scaled.recycle()

            labels.any { label ->
                val text = label.text.lowercase()
                // High-confidence labels alone are sufficient
                (HIGH_CONFIDENCE_LABELS.any { text.contains(it) } && label.confidence >= HIGH_CONFIDENCE_THRESHOLD) ||
                // Other explicit labels at normal threshold
                (EXPLICIT_LABELS.any { text.contains(it) } && label.confidence >= CONFIDENCE_THRESHOLD)
            }
        } catch (e: Exception) {
            Log.e(TAG, "ML analysis failed", e)
            scaled.recycle()
            false
        }
    }

    // FIX: DB insert was calling suspend fun from regular fun — wouldn't compile.
    // Now uses CoroutineScope(IO) for background thread safety.
    private fun logBlock() {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                GuardianDatabase.getInstance(applicationContext)
                    .blockAttemptDao()
                    .insert(
                        BlockAttemptEntity(
                            timestamp = System.currentTimeMillis(),
                            detectedUrl = "screen_analysis",
                            detectionLayer = "MLKit",
                            userOverrode = false
                        )
                    )
            } catch (e: Exception) {
                Log.e(TAG, "logBlock DB write failed", e)
            }
        }
    }

    private fun launchOverlay() {
        try {
            val intent = Intent(this, BlockOverlayActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Overlay launch failed", e)
        }
    }

    private fun createNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Guardian Screen Protection",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Guardian Running")
            .setContentText("Screen protection active")
            .setSmallIcon(android.R.drawable.ic_secure)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        job?.cancel()
        labeler?.close()   // FIX: Close labeler to release native ML resources
        labeler = null
        projection?.stop()
        MediaProjectionHolder.projection = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
