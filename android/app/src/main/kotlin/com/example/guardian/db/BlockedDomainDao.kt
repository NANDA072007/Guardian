// android/app/src/main/kotlin/com/example/guardian/db/BlockedDomainDao.kt
// No changes from original — already correct
package com.example.guardian.db

import androidx.room.Dao
import androidx.room.Query

@Dao
interface BlockedDomainDao {

    // Exact match — uses the domain index. O(log n) on 100k domains.
    @Query("""
        SELECT EXISTS(
            SELECT 1 FROM blocked_domains 
            WHERE domain = :domain
            LIMIT 1
        )
    """)
    suspend fun isExactDomainBlocked(domain: String): Boolean

    // Full load for VPN preload into ConcurrentHashMap
    @Query("SELECT domain FROM blocked_domains")
    suspend fun getAllDomains(): List<String>

    @Query("SELECT COUNT(*) FROM blocked_domains")
    suspend fun getDomainCount(): Int

    // WARNING: LIKE query cannot use index — full table scan on 100k rows.
    // Never use on the VPN hot path. Only for fallback/debug.
    @Query("""
        SELECT EXISTS(
            SELECT 1 FROM blocked_domains 
            WHERE :domain LIKE '%' || domain
            LIMIT 1
        )
    """)
    suspend fun isDomainBlockedBySuffix(domain: String): Boolean
}
