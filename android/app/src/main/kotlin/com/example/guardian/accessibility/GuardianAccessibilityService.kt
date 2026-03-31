// android/app/src/main/kotlin/com/example/guardian/accessibility/GuardianAccessibilityService.kt
package com.example.guardian.accessibility

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import com.example.guardian.db.GuardianDatabase
import com.example.guardian.db.BlockAttemptEntity
import java.util.Locale
import java.util.concurrent.Executors

class GuardianAccessibilityService : AccessibilityService() {

    private val TAG = "GuardianAccessibility"
    private val handler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()

    // Debounce: prevents CPU spike from 100s of events/second
    private var lastProcessedTime = 0L
    private val DEBOUNCE_MS = 200L

    private lateinit var database: GuardianDatabase

    // FIX: Removed "sex" and "adult" — caused constant false positives on
    // WebMD, Wikipedia, news articles, educational sites, adult beverages etc.
    // These broad words are handled by the VPN domain blocklist instead.
    // Accessibility layer focuses only on explicit site names and clear signals.
    private val ADULT_KEYWORDS = setOf(
        // Direct content terms
        "porn", "xxx", "nude", "nudity", "hentai", "nsfw",
        // Major site names — very specific, no false positives
        "pornhub", "xvideos", "xnxx", "xhamster", "redtube",
        "youporn", "onlyfans", "fansly", "brazzers", "bangbros",
        "naughtyamerica", "realitykings", "mofos", "babes",
        "erotica", "naked", "erotic"
    )

    override fun onServiceConnected() {
        super.onServiceConnected()
        database = GuardianDatabase.getInstance(applicationContext)

        val info = AccessibilityServiceInfo().apply {
            eventTypes =
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED or
                AccessibilityEvent.TYPE_VIEW_FOCUSED

            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC

            flags =
                AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS

            notificationTimeout = 100
        }

        serviceInfo = info
        Log.i(TAG, "Guardian Accessibility Service connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        // Debounce — critical for battery
        val now = System.currentTimeMillis()
        if (now - lastProcessedTime < DEBOUNCE_MS) return
        lastProcessedTime = now

        val rootNode = rootInActiveWindow ?: return

        try {
            val text = extractTextBFS(rootNode)
            if (text.isEmpty()) return

            val normalized = text.lowercase(Locale.ROOT)

            // 1. URL detection (highest confidence — exact match)
            val url = extractUrl(normalized)
            if (!url.isNullOrEmpty() && containsAdultKeyword(url)) {
                handleDetection("url", url)
                return
            }

            // 2. Domain extraction (catches address bar text before URL prefix is typed)
            val domain = extractDomain(normalized)
            if (!domain.isNullOrEmpty() && containsAdultKeyword(domain)) {
                handleDetection("domain", domain)
                return
            }

            // 3. General keyword scan (fallback)
            if (containsAdultKeyword(normalized)) {
                handleDetection("keyword", normalized.take(100))
            }

        } catch (e: Exception) {
            Log.e(TAG, "Detection error", e)
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility service interrupted")
    }

    // BFS traversal — faster than recursive DFS, bounded by MAX_NODES
    private fun extractTextBFS(root: AccessibilityNodeInfo?): String {
        if (root == null) return ""

        val sb = StringBuilder()
        val queue = ArrayDeque<AccessibilityNodeInfo>()
        queue.add(root)
        var count = 0
        val MAX_NODES = 150

        while (queue.isNotEmpty() && count < MAX_NODES) {
            val node = queue.removeFirst()
            node.text?.let { sb.append(it).append(" ") }
            node.contentDescription?.let { sb.append(it).append(" ") }
            for (i in 0 until node.childCount) {
                node.getChild(i)?.let { queue.add(it) }
            }
            count++
        }

        return sb.toString()
    }

    private fun extractUrl(text: String): String? {
        for (prefix in listOf("https://", "http://", "www.")) {
            val idx = text.indexOf(prefix)
            if (idx != -1) {
                return text.substring(idx).split(" ", "\n", "\t")[0]
            }
        }
        return null
    }

    private fun extractDomain(text: String): String? {
        val regex = Regex("""([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}""")
        return regex.find(text)?.value
    }

    private fun containsAdultKeyword(text: String): Boolean {
        return ADULT_KEYWORDS.any { text.contains(it) }
    }

    private fun handleDetection(type: String, content: String) {
        Log.w(TAG, "DETECTED [$type]: ${content.take(80)}")
        handler.removeCallbacksAndMessages(null)
        handler.postDelayed({
            logBlockAttempt(type, content)
            launchBlockOverlay()
        }, DEBOUNCE_MS)
    }

    // FIX: DB write on background executor — Room insert is suspend/blocking
    private fun logBlockAttempt(type: String, content: String) {
        executor.execute {
            try {
                database.blockAttemptDao().insertSync(
                    BlockAttemptEntity(
                        timestamp = System.currentTimeMillis(),
                        detectedUrl = content.take(200),
                        detectionLayer = "Accessibility",
                        userOverrode = false
                    )
                )
            } catch (e: Exception) {
                Log.e(TAG, "DB log failed", e)
            }
        }
    }

    private fun launchBlockOverlay() {
        try {
            val intent = Intent().apply {
                setClassName(packageName, "com.example.guardian.block.BlockOverlayActivity")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Overlay launch failed", e)
        }
    }
}
