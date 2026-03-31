# GUARDIAN — God Level Protection App
## Project Context Document (Production)

---

## 1. PROJECT OVERVIEW

**App Name:** Guardian  
**Tagline:** *Your mind. Protected. Forever.*  
**Platform:** Android (Primary), iOS (Future)  
**Type:** System-level content blocker + Recovery companion  
**Purpose:** Help individuals break free from porn addiction through unbypassable technical protection + built-in recovery tools  
**Target User:** Anyone fighting porn/compulsive content addiction who wants a self-built, unkillable blocker

---

## 2. CORE PHILOSOPHY

> The app must be so deeply embedded in the Android system that even the user themselves cannot disable it in a moment of weakness.

The entire app is designed around one truth:  
**Willpower fails. Systems win.**

The user sets up protection ONCE when their willpower is high.  
Then the system protects them even when their willpower is zero.

---

## 3. TECH STACK

| Layer | Technology | Purpose |
|---|---|---|
| UI | Flutter 3.x (Dart) | Cross-platform UI, screens, dashboard |
| Native Android | Kotlin | All system-level APIs |
| Bridge | Flutter Platform Channels (MethodChannel) | Flutter ↔ Kotlin communication |
| Local DB | Room (SQLite via Android) | 100k+ adult domain blocklist storage |
| Secure Storage | flutter_secure_storage | Password hash, config storage |
| Background | WorkManager (Kotlin) | Persistent background tasks |
| Screen Analysis | Google ML Kit (on-device) | Nudity detection from screen |
| Hashing | SHA-256 (Kotlin) | Password protection (never plain text) |
| State Management | Riverpod 2.x | Flutter app state |
| Navigation | GoRouter | Screen routing |

---

## 4. PROTECTION ARCHITECTURE — 4 LAYERS

### Layer 1 — Local VPN Service (DNS Filtering)
- Runs as Android `VpnService`
- Routes ALL device internet traffic through the app itself
- Filters DNS queries against 100k+ adult domain blocklist (Room DB)
- Uses Cloudflare Family DNS (1.1.1.3 / 1.0.0.3) as upstream
- Drops packets for blocked domains before content ever loads
- `START_STICKY` — auto-restarts if killed
- `onRevoke()` immediately re-establishes VPN if system revokes it
- Combined with Android **Lockdown Mode** (Block connections without VPN) = no internet if VPN dies

### Layer 2 — Accessibility Service (URL & Keyword Monitor)
- Runs as Android `AccessibilityService`
- Monitors `TYPE_WINDOW_CONTENT_CHANGED` events across ALL apps
- Extracts URL bar content from every browser (Chrome, Firefox, Brave, Opera, etc.)
- Checks against adult keyword list + domain list in real time
- On detection: launches `BlockOverlayActivity` — full screen block
- Also monitors general screen text for adult keywords
- Cannot be stopped without going to Accessibility Settings (which requires Device Admin password)

### Layer 3 — ML Kit Screen Analyzer
- Uses `ImageLabeling` (Google ML Kit, on-device, no internet needed)
- Runs every 5 seconds via `WorkManager` periodic task
- Captures screen via `MediaProjection` API
- If nudity/skin/adult labels detected with >75% confidence → triggers block overlay
- Fully on-device — no data leaves the phone

### Layer 4 — Device Admin (Anti-Uninstall + Anti-Disable)
- App registers as Android `DeviceAdminReceiver`
- Once activated: app CANNOT be uninstalled without deactivating Device Admin first
- Deactivating Device Admin requires the Guardian password
- Guardian password is hashed (SHA-256) and given to a trusted person — not stored in plain text anywhere
- `onDisableRequested()` shows warning message and requests password

---

## 5. BOOT PERSISTENCE

```
Phone restarts → BootReceiver (RECEIVE_BOOT_COMPLETED) → 
Restarts VPN Service + checks Accessibility Service status
```

All services auto-restart on every phone boot. The protection survives:
- App force stop attempts
- Phone restarts
- Battery optimization kills
- System memory pressure

---

## 6. ALWAYS-ON VPN LOCKDOWN (Android System Level)

After setup, the app guides the user to enable:
```
Settings → Network & Internet → VPN → Guardian VPN ⚙️
→ Always-on VPN: ON
→ Block connections without VPN: ON  ← THE NUCLEAR OPTION
```

**Effect:** If Guardian VPN service ever goes down for ANY reason — all internet on the phone is completely cut off. The phone is useless for browsing without Guardian running. This removes any incentive to try killing the VPN.

---

## 7. PASSWORD SYSTEM

- Password is set ONCE during onboarding
- Immediately hashed with SHA-256 before storage
- Plain text password is shown ONCE in a "handoff dialog"
- User is instructed to send the password to a trusted person (friend/sibling)
- User then deletes the message
- From that point: only the trusted person can disable Guardian
- No "forgot password" flow — by design

### Password Required For:
- Disabling Device Admin
- Turning off VPN service from within the app
- Changing any Guardian settings
- Uninstalling the app

---

## 8. BLOCK OVERLAY

When adult content is detected, `BlockOverlayActivity` is launched:

- Full screen, black background
- Shows: Guardian shield logo
- Message: *"You're stronger than this. Go for a walk."*
- Shows current streak: *"You are on Day 14. Don't lose it."*
- Single button: "I'm okay now" — closes overlay after 10-second countdown (cannot skip)
- Logs attempt to local DB (used for analytics in dashboard)

---

## 9. FLUTTER SCREENS

### Screen 1 — Splash / Entry
- Check if Guardian is already set up
- If yes → Dashboard
- If no → Onboarding

### Screen 2 — Onboarding (Setup Flow)
Step-by-step guided setup:
1. Welcome + explain what Guardian does
2. Set password (with confirm)
3. Activate Device Admin (deep links to system screen)
4. Start VPN Service
5. Enable Accessibility Service (deep links to Accessibility Settings)
6. Show password handoff dialog
7. Done → redirect to Dashboard

### Screen 3 — Dashboard (Home)
- Streak counter (current days clean)
- Streak calendar (visual month view)
- Protection status indicators (VPN ✅ / Accessibility ✅ / Device Admin ✅)
- Block attempt counter ("Guardian has blocked X attempts")
- Daily motivational quote
- Emergency "I'm struggling" button → opens breathing exercise

### Screen 4 — 21-Day Challenge
- Progress bar: Day X of 21
- Daily checklist (morning routine, exercise, phone out of room)
- Week-by-week breakdown with danger zone warnings
- Journal entry for the day
- Milestone celebrations (Day 7, Day 14, Day 21)

### Screen 5 — Analytics
- Weekly/monthly block attempt graph
- Time-of-day heatmap (when attempts happen most)
- Trigger pattern analysis ("Most attempts happen after 10 PM")
- Streak history

### Screen 6 — Emergency (Urge Surfing)
- Activated by "I'm struggling" button or block overlay
- 4-7-8 breathing exercise (animated)
- 10-minute timer with body movement instructions
- "Read your why" — shows the user's Day 1 journal entry
- Call/text accountability person button

### Screen 7 — Settings (Password Protected)
- Change accountability person contact
- View protection status
- Export streak data
- Disable Guardian (password required → shows warning → requires trusted person)

---

## 10. DATA MODELS

### StreakRecord
```dart
class StreakRecord {
  final int id;
  final DateTime startDate;
  final DateTime? endDate;       // null if current streak
  final int totalDays;
  final String? relapseReason;  // optional journal note
}
```

### BlockAttempt
```dart
class BlockAttempt {
  final int id;
  final DateTime timestamp;
  final String detectedUrl;     // or "screen_analysis" or "keyword"
  final String detectionLayer;  // "VPN", "Accessibility", "MLKit"
  final bool userOverrode;      // always false — cannot override
}
```

### DailyCheckIn
```dart
class DailyCheckIn {
  final int id;
  final DateTime date;
  final bool morningRoutineDone;
  final bool exerciseDone;
  final bool phoneOutOfRoom;
  final String journalEntry;
  final int moodScore;          // 1-10
}
```

### GuardianConfig (Secure Storage)
```dart
class GuardianConfig {
  final String passwordHash;         // SHA-256 hash
  final String accountabilityName;   // trusted person's name
  final String accountabilityPhone;  // trusted person's number
  final DateTime setupDate;
  final bool deviceAdminActive;
  final bool vpnActive;
  final bool accessibilityActive;
}
```

---

## 11. PLATFORM CHANNELS (Flutter ↔ Kotlin)

Channel name: `guardian/protection`

| Method | Direction | Description |
|---|---|---|
| `activateDeviceAdmin` | Flutter → Kotlin | Launches Device Admin activation intent |
| `startVpn` | Flutter → Kotlin | Starts GuardianVpnService |
| `stopVpn` | Flutter → Kotlin | Stops VPN (password verified first) |
| `isVpnRunning` | Flutter → Kotlin | Returns bool |
| `isDeviceAdminActive` | Flutter → Kotlin | Returns bool |
| `isAccessibilityEnabled` | Flutter → Kotlin | Returns bool |
| `openAccessibilitySettings` | Flutter → Kotlin | Deep links to system Accessibility Settings |
| `openVpnSettings` | Flutter → Kotlin | Deep links to VPN Settings (for Lockdown Mode) |
| `getBlockAttemptCount` | Flutter → Kotlin | Returns int from Room DB |
| `verifyPassword` | Flutter → Kotlin | Takes raw string, compares SHA-256 hash |

---

## 12. ANDROID MANIFEST — REQUIRED PERMISSIONS

```xml
<!-- Core Protection -->
<uses-permission android:name="android.permission.BIND_VPN_SERVICE"/>
<uses-permission android:name="android.permission.BIND_ACCESSIBILITY_SERVICE"/>
<uses-permission android:name="android.permission.BIND_DEVICE_ADMIN"/>

<!-- Persistence -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>

<!-- Screen Analysis -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION"/>

<!-- Network -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<!-- Battery -->
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
```

---

## 13. BLOCKLIST DATABASE

- **Size:** 100,000+ adult domains
- **Storage:** Room DB (local SQLite) — works offline
- **Source:** Open source lists (StevenBlack/hosts, oisd.nl blocklist)
- **Structure:**
  ```sql
  CREATE TABLE blocked_domains (
    id INTEGER PRIMARY KEY,
    domain TEXT UNIQUE NOT NULL,
    category TEXT,              -- 'porn', 'adult', 'gambling', 'social_nsfw'
    added_at INTEGER
  );
  ```
- **Updates:** Bundled with app at build time. Manual update via Settings.
- **Lookup:** Indexed on `domain` column — O(log n) lookup per DNS query

---

## 14. KEYWORD BLOCKLIST (Accessibility Layer)

Categories monitored in URL bars and screen text:

```kotlin
val ADULT_KEYWORDS = listOf(
    // Direct
    "porn", "xxx", "nude", "nudity", "hentai", "nsfw",
    // Sites
    "pornhub", "xvideos", "xnxx", "xhamster", "redtube",
    "youporn", "onlyfans", "fansly", "brazzers",
    // Search terms
    "naked", "erotic", "sex video", "adult video",
    // Regional variants (add based on user locale)
)
```

---

## 15. BACKGROUND SERVICE STRATEGY

| Service | Type | Restart Strategy |
|---|---|---|
| GuardianVpnService | Foreground Service | START_STICKY + onRevoke() restart |
| GuardianAccessibilityService | System Service | Auto by Android if accessibility enabled |
| BootReceiver | BroadcastReceiver | Triggered by BOOT_COMPLETED |
| ScreenAnalyzer | WorkManager Periodic | Every 5 mins, survives reboots |

**Battery optimization:** App requests to be excluded from battery optimization during setup (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`). User is guided through this in onboarding.

---

## 16. FOLDER STRUCTURE

```
guardian/
├── android/
│   └── app/src/main/
├── kotlin/com/guardian/
│   ├── MainActivity.kt
│
│   ├── vpn/
│   │   └── GuardianVpnService.kt
│
│   ├── accessibility/
│   │   └── GuardianAccessibilityService.kt
│
│   ├── ml/
│   │   └── ScreenAnalyzer.kt
│
│   ├── admin/
│   │   └── GuardianDeviceAdmin.kt
│
│   ├── receiver/
│   │   └── BootReceiver.kt
│
│   └── db/
│       ├── GuardianDatabase.kt
│       ├── BlockedDomainDao.kt
│       └── BlockAttemptDao.kt
│
├── res/xml/
│   ├── device_admin.xml
│   └── accessibility_config.xml
│
└── AndroidManifest.xml
│
lib/
├── main.dart
├── app.dart
│
├── core/
│   ├── constants.dart
│   ├── secure_storage.dart
│   └── password_hasher.dart
│
├── models/
│   ├── streak_record.dart
│   ├── block_attempt.dart
│   ├── daily_checkin.dart
│   └── guardian_config.dart
│
├── providers/
│   ├── protection_provider.dart
│   ├── streak_provider.dart
│   └── config_provider.dart
│
├── services/
│   ├── protection_service.dart
│   ├── streak_service.dart
│   └── notification_service.dart
│
├── screens/
│   ├── splash_screen.dart
│   │
│   ├── onboarding/
│   │   ├── welcome_screen.dart
│   │   ├── set_password_screen.dart
│   │   ├── activate_admin_screen.dart
│   │   ├── enable_vpn_screen.dart
│   │   ├── enable_accessibility_screen.dart
│   │   └── password_handoff_screen.dart
│   │
│   ├── dashboard_screen.dart
│   ├── challenge_screen.dart
│   ├── analytics_screen.dart
│   ├── emergency_screen.dart
│   ├── block_overlay_screen.dart
│   └── settings_screen.dart
│
└── widgets/
    ├── streak_calendar.dart
    ├── protection_status_card.dart
    ├── breathing_exercise.dart
    └── motivational_quote.dart
│
├── assets/
│   ├── blocklist/
│   │   └── adult_domains.db                ← Pre-built Room DB (bundled)
│   ├── fonts/
│   └── images/
│       └── guardian_shield.svg
│
├── pubspec.yaml
├── CONTEXT.md                               ← This file
└── README.md
```

---

## 17. BUILD ORDER (4 Weeks)

### Week 1 — Foundation + VPN (Core Blocker)
- [ ] Flutter project init with Riverpod + GoRouter
- [ ] Kotlin platform channel boilerplate in MainActivity
- [ ] `GuardianVpnService.kt` — DNS filtering with Room DB
- [ ] `BootReceiver.kt` — boot persistence
- [ ] Import and bundle StevenBlack adult domain list into Room DB
- [ ] Onboarding Screens 1-3 (Welcome, Password, VPN setup)
- [ ] Test: VPN blocks pornhub, xvideos, etc. on real device

### Week 2 — Smart Detection
- [ ] `GuardianAccessibilityService.kt` — URL monitoring + keyword detection
- [ ] `BlockOverlayActivity` — full screen block with streak display
- [ ] Onboarding Screens 4-5 (Accessibility + handoff)
- [ ] Block attempt logging to Room DB
- [ ] Test: Typing adult URL in Chrome triggers overlay

### Week 3 — God Mode
- [ ] `GuardianDeviceAdmin.kt` — Device Admin registration
- [ ] Password verification flow (all sensitive actions gated)
- [ ] `ScreenAnalyzer.kt` — ML Kit integration via WorkManager
- [ ] Always-On VPN guide screen (with step-by-step screenshots)
- [ ] Test: App cannot be uninstalled without password

### Week 4 — Recovery Companion
- [ ] Dashboard with streak tracker + calendar
- [ ] 21-Day Challenge screen with daily checklist
- [ ] Emergency / Urge Surfing screen (breathing animation)
- [ ] Analytics screen (block attempts, time heatmap)
- [ ] Motivational notifications (morning, night)
- [ ] Danger zone alerts (Day 18-21 push notifications)
- [ ] Final end-to-end test on real device

---

## 18. THIRD-PARTY DEPENDENCIES

### Flutter (pubspec.yaml)
```yaml
dependencies:
  flutter_riverpod: ^2.5.1
  go_router: ^13.2.0
  flutter_secure_storage: ^9.0.0
  crypto: ^3.0.3           # SHA-256 hashing
  local_notifications: ^17.0.0
  shared_preferences: ^2.2.2
  intl: ^0.19.0
  fl_chart: ^0.68.0        # Analytics charts
  lottie: ^3.1.0           # Breathing animation

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.3
```

### Android (build.gradle)
```gradle
// Room DB
implementation "androidx.room:room-runtime:2.6.1"
kapt "androidx.room:room-compiler:2.6.1"

// WorkManager
implementation "androidx.work:work-runtime-ktx:2.9.0"

// ML Kit
implementation "com.google.mlkit:image-labeling:17.0.8"
```

---

## 19. KNOWN ANDROID LIMITATIONS & WORKAROUNDS

| Limitation | Workaround |
|---|---|
| Android 10+ restricts background screen capture | Use `MediaProjection` with foreground service notification |
| VPN can be disabled from Quick Settings tile | Lockdown Mode makes this cut ALL internet — user has no benefit |
| Accessibility service can be disabled in Settings | Device Admin + password warning on `onDisableRequested()` |
| App can be force-stopped | `START_STICKY` + WorkManager ensures restart. Battery exemption prevents kill. |
| Device Admin can be disabled (requires password flow) | Password held by trusted person — they are the human firewall |
| iOS: No VPN service / Device Admin equivalent | iOS version: Use Screen Time API + DNS profile (future scope) |

---

## 20. SECURITY PRINCIPLES

1. **Never store plain text password** — SHA-256 hash only
2. **No remote server** — everything is local, no data leaves the device
3. **No backdoor** — even the developer cannot bypass Device Admin without the password
4. **Fail-safe design** — if VPN fails, Lockdown Mode cuts all internet
5. **Minimal permissions** — only request what each layer specifically needs
6. **Trusted person model** — human accountability is the final layer, not just code

---

## 21. FUTURE SCOPE (Post MVP)

- [ ] iOS version using Screen Time API + DNS-over-HTTPS profile
- [ ] Accountability partner app (companion app for the trusted person)
- [ ] WhatsApp integration: auto-send streak updates to accountability partner
- [ ] Scheduled protection (extra strict mode during night hours)
- [ ] Community streaks (anonymous leaderboard)
- [ ] Therapist connect feature
- [ ] Wear OS companion (streak on wrist)

---

## 22. GOLDEN RULE OF THIS PROJECT

> Every feature, every design decision, every line of code must answer one question:
> **"Does this make it harder for the user to slip — even against their own will in their weakest moment?"**
> If yes → build it.
> If no → skip it.