// android/app/src/main/kotlin/com/example/guardian/db/BlockAttemptEntity.kt
// FIX: Was in same file as BlockedDomainEntity with @Entity annotations on wrong class.
// Split into separate files. Each entity gets its own @Entity annotation.
package com.example.guardian.db

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "block_attempts",
    indices = [
        Index(value = ["timestamp"]),
        Index(value = ["detectionLayer"]),
        Index(value = ["detectedUrl"])
    ]
)
data class BlockAttemptEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Int = 0,

    @ColumnInfo(name = "timestamp")
    val timestamp: Long,

    // URL or identifier: "pornhub.com", "keyword", "screen_analysis"
    @ColumnInfo(name = "detectedUrl")
    val detectedUrl: String,

    // Which layer caught it: "VPN", "Accessibility", "MLKit"
    @ColumnInfo(name = "detectionLayer")
    val detectionLayer: String,

    // Always false — no override is allowed
    @ColumnInfo(name = "userOverrode")
    val userOverrode: Boolean = false
)
