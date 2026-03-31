// android/app/src/main/kotlin/com/example/guardian/db/BlockAttemptDao.kt
package com.example.guardian.db

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface BlockAttemptDao {

    // ========================= INSERT =========================

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(attempt: BlockAttemptEntity): Long

    // FIX: Non-suspend version for callers that can't use coroutines
    // Used by: AccessibilityService (runs on executor), ScreenCaptureService
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    fun insertSync(attempt: BlockAttemptEntity): Long

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(attempts: List<BlockAttemptEntity>): List<Long>

    // ========================= COUNTS =========================

    @Query("SELECT COUNT(*) FROM block_attempts")
    suspend fun getTotalCount(): Int

    // Non-suspend for platform channel executor (MainActivity.getBlockAttemptCount)
    @Query("SELECT COUNT(*) FROM block_attempts")
    fun getTotalCountSync(): Int

    @Query("SELECT COUNT(*) FROM block_attempts WHERE timestamp >= :since")
    suspend fun getCountSince(since: Long): Int

    @Query("SELECT COUNT(*) FROM block_attempts WHERE detectionLayer = :layer")
    suspend fun getCountByLayer(layer: String): Int

    @Query("SELECT COUNT(*) FROM block_attempts WHERE detectionLayer = :layer AND timestamp >= :since")
    suspend fun getLayerCountSince(layer: String, since: Long): Int

    // ========================= FETCH =========================

    @Query("SELECT * FROM block_attempts WHERE :limit > 0 ORDER BY timestamp DESC LIMIT :limit")
    suspend fun getRecent(limit: Int): List<BlockAttemptEntity>

    @Query("SELECT * FROM block_attempts WHERE timestamp BETWEEN :start AND :end ORDER BY timestamp ASC")
    suspend fun getBetween(start: Long, end: Long): List<BlockAttemptEntity>

    @Query("SELECT * FROM block_attempts ORDER BY timestamp DESC LIMIT 1")
    suspend fun getLatest(): BlockAttemptEntity?

    @Query("SELECT * FROM block_attempts WHERE detectionLayer = :layer ORDER BY timestamp DESC LIMIT 1")
    suspend fun getLatestByLayer(layer: String): BlockAttemptEntity?

    // ========================= ANALYTICS =========================

    @Query("""
        SELECT 
            strftime('%H', timestamp / 1000, 'unixepoch') AS hour,
            COUNT(*) as count
        FROM block_attempts
        GROUP BY hour
        ORDER BY hour
    """)
    suspend fun getHourlyDistribution(): List<HourlyCount>

    // ========================= FLOW (real-time UI) =========================

    @Query("SELECT * FROM block_attempts ORDER BY timestamp DESC")
    fun observeAll(): Flow<List<BlockAttemptEntity>>

    @Query("SELECT COUNT(*) FROM block_attempts")
    fun observeCount(): Flow<Int>

    @Query("SELECT COUNT(*) FROM block_attempts WHERE timestamp >= :since")
    fun observeCountSince(since: Long): Flow<Int>

    // ========================= ADMIN ONLY =========================
    // NEVER expose this without password verification
    @Query("DELETE FROM block_attempts")
    suspend fun clearAll()
}

data class HourlyCount(
    val hour: String,   // "00" - "23"
    val count: Int
)
