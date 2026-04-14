package com.example.guardian.db

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface BlockedDomainDao {

    // ✅ INSERT (NEW — REQUIRED)
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertAll(domains: List<BlockedDomainEntity>)

    // Exact match — fast lookup
    @Query("""
        SELECT EXISTS(
            SELECT 1 FROM blocked_domains 
            WHERE domain = :domain
            LIMIT 1
        )
    """)
    suspend fun isExactDomainBlocked(domain: String): Boolean

    // Load all domains for VPN
    @Query("SELECT domain FROM blocked_domains")
    suspend fun getAllDomains(): List<String>

    @Query("SELECT COUNT(*) FROM blocked_domains")
    suspend fun getDomainCount(): Int

    // Slow — do NOT use in VPN loop
    @Query("""
        SELECT EXISTS(
            SELECT 1 FROM blocked_domains 
            WHERE :domain LIKE '%' || domain
            LIMIT 1
        )
    """)
    suspend fun isDomainBlockedBySuffix(domain: String): Boolean
}