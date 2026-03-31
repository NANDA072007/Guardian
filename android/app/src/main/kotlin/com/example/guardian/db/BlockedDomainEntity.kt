// android/app/src/main/kotlin/com/example/guardian/db/BlockedDomainEntity.kt
// NEW FILE: Extracted from BlockAttemptEntity.kt where it was incorrectly placed
package com.example.guardian.db

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "blocked_domains",
    indices = [Index(value = ["domain"], unique = true)]
)
data class BlockedDomainEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Int = 0,
    val domain: String,               // e.g. "pornhub.com" — indexed, unique
    val category: String,             // "porn", "adult", "gambling", "social_nsfw"
    val addedAt: Long
)
