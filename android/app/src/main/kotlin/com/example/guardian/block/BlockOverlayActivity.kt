// android/app/src/main/kotlin/com/example/guardian/block/BlockOverlayActivity.kt
// FIX: Package was "com.guardian.block" — must be "com.example.guardian.block"
package com.example.guardian.block

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class BlockOverlayActivity : FlutterActivity() {

    companion object {
        fun launch(context: Context) {
            val intent = Intent(context, BlockOverlayActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            context.startActivity(intent)
        }
    }

    // FIX: Tell Flutter to load /block-overlay instead of the default /splash route.
    // Without this, FlutterActivity defaults to /splash → SplashScreen → /dashboard.
    // The user would see the Dashboard instead of the block overlay.
    // The AndroidManifest meta-data "InitialRoute" sets this too — this is the code backup.
    override fun getInitialRoute(): String = "/block-overlay"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Full-screen lock mode — sits above all apps
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_FULLSCREEN or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            // FLAG_SECURE prevents screenshots of the overlay screen
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    // Hard block back button — cannot be dismissed
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Intentionally empty — no exit via back button
    }
}
