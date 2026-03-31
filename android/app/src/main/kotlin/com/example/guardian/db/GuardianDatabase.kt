// android/app/src/main/kotlin/com/example/guardian/db/GuardianDatabase.kt
package com.example.guardian.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import java.util.concurrent.Executors

@Database(
    entities = [
        BlockAttemptEntity::class,
        BlockedDomainEntity::class
    ],
    version = 2,
    exportSchema = false
)
abstract class GuardianDatabase : RoomDatabase() {

    abstract fun blockAttemptDao(): BlockAttemptDao
    abstract fun blockedDomainDao(): BlockedDomainDao

    companion object {
        @Volatile
        private var INSTANCE: GuardianDatabase? = null

        // FIX: Real migration instead of fallbackToDestructiveMigration()
        // v1 had only block_attempts. v2 adds blocked_domains.
        // Users upgrading from v1 keep ALL their block attempt history.
        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(database: SupportSQLiteDatabase) {
                database.execSQL("""
                    CREATE TABLE IF NOT EXISTS blocked_domains (
                        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                        domain TEXT NOT NULL,
                        category TEXT NOT NULL,
                        addedAt INTEGER NOT NULL
                    )
                """.trimIndent())
                database.execSQL(
                    "CREATE UNIQUE INDEX IF NOT EXISTS index_blocked_domains_domain ON blocked_domains(domain)"
                )
            }
        }

        fun getInstance(context: Context): GuardianDatabase {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    GuardianDatabase::class.java,
                    "guardian_db"
                )
                    .addMigrations(MIGRATION_1_2)
                    .setQueryExecutor(Executors.newFixedThreadPool(4))
                    .setTransactionExecutor(Executors.newFixedThreadPool(2))
                    .build()
                    .also { INSTANCE = it }
            }
        }
    }
}
