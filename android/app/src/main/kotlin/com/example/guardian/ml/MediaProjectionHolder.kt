// android/app/src/main/kotlin/com/example/guardian/ml/MediaProjectionHolder.kt
// Singleton that holds the MediaProjection across service boundaries
package com.example.guardian.ml

import android.media.projection.MediaProjection

object MediaProjectionHolder {
    @Volatile
    var projection: MediaProjection? = null
}
