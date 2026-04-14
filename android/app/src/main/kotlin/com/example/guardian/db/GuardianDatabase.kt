package com.example.guardian.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import java.util.concurrent.Executors

// ✅ ADD THESE IMPORTS (CRITICAL FIX)
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

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

                    // ✅ FIXED: Coroutine-based seeding
                    .addCallback(object : RoomDatabase.Callback() {
                        override fun onCreate(db: SupportSQLiteDatabase) {
                            super.onCreate(db)

                            CoroutineScope(Dispatchers.IO).launch {
                                val database = getInstance(context)
                                val dao = database.blockedDomainDao()

                                val now = System.currentTimeMillis()

                                val domains = listOf(
                                    BlockedDomainEntity(
                                        domain = "pornhub.com",
                                        category = "porn",
                                        addedAt = now
                                    ),
                                    BlockedDomainEntity(
                                        domain = "xvideos.com",
                                        category = "porn",
                                        addedAt = now
                                    ),
                                    BlockedDomainEntity(
                                        domain = "xnxx.com",
                                        category = "porn",
                                        addedAt = now
                                    ),
                                    BlockedDomainEntity(
                                        domain = "redtube.com",
                                        category = "porn",
                                        addedAt = now
                                    )
                                )

                                dao.insertAll(domains)
                            }
                        }
                    })

                    .setQueryExecutor(Executors.newFixedThreadPool(4))
                    .setTransactionExecutor(Executors.newFixedThreadPool(2))
                    .build()
                    .also { INSTANCE = it }
            }
        }
    }
}

