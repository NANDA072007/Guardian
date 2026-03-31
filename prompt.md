# GUARDIAN — AI Prompt Library
> Production-grade prompt toolkit for building, reviewing, and shipping Guardian.
> Every prompt here is designed to extract senior-engineer-level output from AI.
> Use before writing code, after writing code, and before every commit.

---

## HOW TO USE THIS FILE

1. **Pick the prompt category** that matches what you're about to do
2. **Copy the prompt**, fill in the `[PLACEHOLDERS]` with your actual code or context
3. **Paste your code AFTER the prompt** — always give full context, never a snippet
4. **Run the Output through the P1/P2/P3 filter** — fix P1s before you move on

> **Golden Rule of this prompt file:** Every prompt must produce output that answers:
> *"Does this make it harder for the user to slip — even in their weakest moment?"*

---

## TABLE OF CONTENTS

1. [Pre-Code Planning Prompts](#1-pre-code-planning-prompts)
2. [Code Generation Prompts](#2-code-generation-prompts)
3. [AI Code Review (Meta-Style)](#3-ai-code-review-meta-style)
4. [Layer-Specific Review Prompts](#4-layer-specific-review-prompts)
5. [Flutter / Dart Specific Prompts](#5-flutter--dart-specific-prompts)
6. [Kotlin / Android Specific Prompts](#6-kotlin--android-specific-prompts)
7. [Security & Password System Prompts](#7-security--password-system-prompts)
8. [Bug Diagnosis Prompts](#8-bug-diagnosis-prompts)
9. [Testing Prompts](#9-testing-prompts)
10. [Refactor Prompts](#10-refactor-prompts)
11. [Performance Prompts](#11-performance-prompts)
12. [UX & Recovery Flow Prompts](#12-ux--recovery-flow-prompts)
13. [Pre-Commit Final Check](#13-pre-commit-final-check)
14. [Weekly Codebase Health Check](#14-weekly-codebase-health-check)

---

## 1. PRE-CODE PLANNING PROMPTS

Use these BEFORE writing a single line of code. Forces you to think architecture first.

---

### 1.1 — Feature Architecture Planner

```
You are a senior Android + Flutter engineer who has built production-grade 
system-level apps. I am building "Guardian" — a porn-blocking app for Android
that operates at 4 layers: VPN (DNS filtering), Accessibility Service (URL 
monitoring), ML Kit screen analysis, and Device Admin (anti-uninstall).

I am about to build: [FEATURE NAME]

Before I write any code, help me plan:

1. ARCHITECTURE — Which files will this touch? List every file in 
   the Guardian folder structure that will be created or modified.

2. FLUTTER vs KOTLIN SPLIT — What logic belongs in Dart vs Kotlin? 
   Be specific. Guardian uses Platform Channels for the bridge.

3. STATE — What Riverpod providers will this need? Should I use 
   AsyncNotifier, Notifier, or StreamProvider?

4. DATA — Does this need a Room DB table? If yes, write the schema.
   If it reads from existing tables, write the DAO query.

5. FAILURE MODES — What are 3 ways this feature can silently break 
   on a real Android device without crashing? How do I detect each?

6. ORDER OF IMPLEMENTATION — Give me a step-by-step build order so
   I never write code that depends on something I haven't built yet.

Do NOT write any code yet. Only the plan.
```

---

### 1.2 — Platform Channel Contract Definer

```
I need to add a new Platform Channel method to Guardian.
Channel name is: guardian/protection

The feature I need bridged is: [DESCRIBE WHAT FLUTTER NEEDS FROM KOTLIN]

Define the full contract for this method:

1. METHOD NAME — follow Guardian's existing camelCase naming convention

2. FLUTTER SIDE (Dart) — exact MethodChannel.invokeMethod call signature,
   including parameter types and return type with null safety

3. KOTLIN SIDE — exact when branch in the MethodChannel handler,
   including the types being cast from the call.arguments map

4. ERROR HANDLING — what PlatformException codes should Kotlin throw,
   and how should Dart catch and surface them to the user?

5. LOADING STATE — does this method take >200ms? If so, how should 
   the Flutter UI handle the async wait without freezing?

Return a Dart snippet and a Kotlin snippet that are mirror-image 
contracts of each other.
```

---

### 1.3 — Room DB Schema Designer

```
I need to add a new Room DB entity to Guardian (Android, Kotlin).
Guardian already has: blocked_domains and block_attempts tables.

New entity purpose: [DESCRIBE WHAT DATA THIS STORES]

Design the complete Room setup:

1. ENTITY CLASS — Kotlin @Entity data class with all fields, 
   proper types, @PrimaryKey, and indexes on any column that 
   will be used in WHERE or ORDER BY clauses

2. DAO INTERFACE — all @Query, @Insert, @Update, @Delete methods 
   this feature will realistically need, including any JOIN queries

3. MIGRATION — a Room Migration block from the current version to 
   the new version (assume current DB version is [CURRENT VERSION])

4. DART MODEL — the matching Dart model class that mirrors this entity,
   for use on the Flutter side after platform channel return

Flag any design decisions I should reconsider before writing this.
```

---

## 2. CODE GENERATION PROMPTS

Use these when asking AI to write new Guardian code from scratch.

---

### 2.1 — Guardian Code Writer (Master Prompt)

```
You are a senior Flutter + Android engineer. Write production-grade code for 
Guardian — an Android porn-blocking app.

Guardian's rules:
- Flutter 3.x with Riverpod 2.x (AsyncNotifier pattern) and GoRouter
- Kotlin for all system-level Android APIs
- Platform Channels (channel: "guardian/protection") for Flutter ↔ Kotlin
- Room DB for local persistence (blocklist + logs)
- flutter_secure_storage for password hash and config
- SHA-256 hashing for ALL password handling — never plain text
- START_STICKY on all services
- Every sensitive action MUST verify the SHA-256 password hash before proceeding
- No backend, no network calls except DNS upstream — everything is local

Write: [WHAT YOU NEED]

Requirements:
- No tutorial-level code. No TODO comments in logic. No placeholder functions.
- Handle every null, every empty state, every permission denial.
- Follow sealed class exception hierarchy for errors.
- If this is a Riverpod provider, use ref.watch + ref.read correctly.
- If this touches the VPN, Accessibility, or Device Admin — add the 
  service lifecycle comments explaining WHY each lifecycle method does what it does.
```

---

### 2.2 — Block Overlay Screen Writer

```
Write the Flutter BlockOverlayScreen for Guardian. This screen is launched 
directly by Kotlin (not Flutter navigation) when adult content is detected.

Requirements:
- Full screen, near-black background (#0D1117)
- Guardian shield logo centered at top
- Motivational message: "You're stronger than this. Go for a walk."
- Display current streak from Riverpod streak_provider: "You are on Day X. Don't lose it."
- Single button: "I'm okay now" — DISABLED for 10 seconds, then enabled
- 10-second countdown displayed on the button
- On button press: call platform channel method to log the block attempt was closed
- Log this block attempt to Room DB via platform channel getBlockAttemptCount
- DO NOT have a back button. DO NOT respond to Android back gesture.
- The user CANNOT leave this screen until the countdown finishes.

Use Riverpod for streak data. Use Platform Channel for logging.
Handle the case where streak data is loading or unavailable gracefully.
```

---

### 2.3 — Onboarding Step Writer

```
Write onboarding step [STEP NUMBER]: [STEP NAME] for Guardian.

Context of the full onboarding flow:
Step 1 — Welcome
Step 2 — Set Password  
Step 3 — Activate Device Admin
Step 4 — Start VPN Service
Step 5 — Enable Accessibility Service
Step 6 — Password Handoff Dialog
Step 7 — Done

For this step, write:
1. The Flutter screen Dart file (screens/onboarding/[step_name]_screen.dart)
2. Any Kotlin platform channel calls needed (list method names only, not full Kotlin)
3. The GoRouter route definition for this step
4. Validation: what must be TRUE before the user can tap "Continue"?
   - If the condition is not met, show a specific error — not a generic snackbar.

The screen must be unable to be skipped. If the system action fails (e.g., 
user denies Device Admin), show a specific explanation of WHY it is required,
not just an error.
```

---

## 3. AI CODE REVIEW (META-STYLE)

The core review prompt. Run this on EVERY feature before calling it done.

---

### 3.1 — Full Feature Review (The Main One)

```
Review this Guardian code as a senior Android + Flutter engineer.

Guardian is a porn-blocking app with 4 protection layers:
- Layer 1: VPN Service (DNS filtering, 100k domain blocklist in Room DB)
- Layer 2: Accessibility Service (URL + keyword monitoring)  
- Layer 3: ML Kit Screen Analyzer (WorkManager, every 5 mins)
- Layer 4: Device Admin (anti-uninstall, password-gated)

Password system: SHA-256 hash only. Plain text never stored. No recovery flow.
Trusted person model: only the trusted person has the plain text password.

Check for:

1. SECURITY
   - Is SHA-256 hashing used everywhere a password is touched?
   - Is there any path to disable a protection layer WITHOUT password verification?
   - Is any sensitive data (password, accountability contact) stored in plain text?
   - Are there any implicit intents that a malicious app could intercept?

2. ANDROID SERVICE RESILIENCE
   - Will this survive an app force-stop?
   - Will this survive a phone restart?
   - Does every Foreground Service have START_STICKY?
   - Does onRevoke() re-establish the VPN immediately?
   - Will Android battery optimization kill this silently?

3. PLATFORM CHANNEL SAFETY
   - Are all platform channel return types null-checked on the Dart side?
   - Is PlatformException caught separately from generic exceptions?
   - Are method names consistent with guardian/protection channel conventions?

4. RIVERPOD CORRECTNESS
   - Is ref.watch used in build() and ref.read in callbacks? (not swapped)
   - Are there any providers that could cause infinite rebuild loops?
   - Is AsyncValue handled with .when() covering loading, data, AND error?

5. ROOM DB SAFETY
   - Are all DB operations on a background thread? (suspend functions or IO dispatcher)
   - Are domain lookups using the indexed column?
   - Is there a migration if the schema changed?

6. EDGE CASES
   - What happens if the Room DB is empty or not seeded yet?
   - What if the Accessibility Service fires before the VPN is ready?
   - What if ML Kit returns null labels?
   - What if the user revokes a permission after setup?

7. WHAT I MISSED
   - What production behavior did I not think about that will break 
     on a real device in real conditions?

Give me:
P1 = Fix before shipping (security or data loss risk)
P2 = Fix this week (reliability risk)
P3 = Note for later (quality improvement)

[PASTE YOUR CODE BELOW THIS LINE]
```

---

### 3.2 — Quick Spot-Check (For Small Changes)

```
Quick Guardian code review. 3 minutes, not 30.

I changed: [ONE LINE DESCRIPTION OF WHAT CHANGED]

Check only:
1. Does this break any protection layer?
2. Is there any path where password verification is now skippable?
3. Does this survive service restart / phone reboot?
4. Any null pointer risk in the Dart ↔ Kotlin bridge?

Flag only P1s. Skip everything else.

[PASTE CODE]
```

---

## 4. LAYER-SPECIFIC REVIEW PROMPTS

Focused reviews for each of Guardian's 4 protection layers.

---

### 4.1 — Layer 1: VPN Service Review

```
Review this GuardianVpnService Kotlin code specifically for VPN correctness.

Guardian's VPN requirements:
- Routes ALL traffic through the local VPN tunnel
- Filters DNS queries against Room DB blocklist (100k+ adult domains)
- Uses Cloudflare Family DNS 1.1.1.3 / 1.0.0.3 as upstream
- Must use START_STICKY
- onRevoke() must immediately re-establish the VPN
- Works with Android Lockdown Mode (Block connections without VPN)

Check:
1. Is the VPN builder configuration correct for a DNS-filtering-only tunnel?
2. Will this survive onRevoke() being called by the system?
3. Is the DNS packet parsing handling both A and AAAA records?
4. Will the blocklist Room DB query block the VPN packet processing thread?
5. Is the foreground service notification present and correct?
6. What happens on Android 10+ with the VPN permission dialog?
7. Does this interact correctly with Lockdown Mode?

[PASTE GuardianVpnService.kt]
```

---

### 4.2 — Layer 2: Accessibility Service Review

```
Review this GuardianAccessibilityService Kotlin code.

Guardian's Accessibility requirements:
- Monitors TYPE_WINDOW_CONTENT_CHANGED across ALL apps
- Extracts URL bar content from Chrome, Firefox, Brave, Opera, etc.
- Checks against ADULT_KEYWORDS list and blocked domain list
- On detection: launches BlockOverlayActivity as a new task
- Must NOT be stoppable without Device Admin password

Check:
1. Is TYPE_WINDOW_CONTENT_CHANGED the right event type, or should 
   TYPE_VIEW_TEXT_CHANGED also be monitored for search bars?
2. Is the URL extraction logic robust across different browser 
   accessibility tree structures? (Chrome vs Firefox node IDs differ)
3. Is the keyword check case-insensitive?
4. Is BlockOverlayActivity launched with FLAG_ACTIVITY_NEW_TASK?
5. Is there debouncing? (event fires hundreds of times per second)
6. What happens if onAccessibilityEvent is called on a background thread?
7. Will this drain battery unacceptably? Estimate events/second.

[PASTE GuardianAccessibilityService.kt]
```

---

### 4.3 — Layer 3: ML Kit Screen Analyzer Review

```
Review this ScreenAnalyzer Kotlin code (ML Kit + WorkManager).

Guardian's ML Kit requirements:
- Uses Google ML Kit ImageLabeling, on-device only
- Triggered every 5 minutes by WorkManager periodic task
- Captures screen via MediaProjection API
- Confidence threshold: >75% for nudity/adult labels
- On detection: launches BlockOverlayActivity
- No data leaves the device

Check:
1. Is the WorkManager PeriodicWorkRequest configured correctly 
   for 5-minute intervals that survive reboots?
2. Is MediaProjection being used correctly on Android 10+ 
   (requires FOREGROUND_SERVICE_MEDIA_PROJECTION)?
3. Is the InputImage created correctly from the screen bitmap?
4. Is the 75% confidence threshold being applied to the RIGHT labels?
   (ML Kit label names for adult content are not obvious — verify)
5. What is the memory footprint of this operation? Is the bitmap 
   being recycled after processing?
6. Is the WorkManager constraint set to require the screen to be on?
   (pointless to analyze screen when phone is locked)
7. What happens if MediaProjection permission is revoked between 
   setup and the WorkManager task running?

[PASTE ScreenAnalyzer.kt]
```

---

### 4.4 — Layer 4: Device Admin Review

```
Review this GuardianDeviceAdmin Kotlin code.

Guardian's Device Admin requirements:
- Prevents uninstall without deactivating Device Admin first
- onDisableRequested() must verify SHA-256 password before allowing deactivation
- onDisableRequested() returns a warning message to show the user
- Password is hashed, held by trusted person — no recovery

Check:
1. Is onDisableRequested() actually able to block deactivation, or does 
   Android always allow it? (research: Android's actual behavior here)
2. Is the password verification using the same SHA-256 implementation 
   as the rest of Guardian?
3. Can a user bypass this by going to Settings → Apps → Guardian → Uninstall 
   WITHOUT going through Device Admin deactivation first?
4. What happens on Android work profile devices?
5. Is device_admin.xml declaring the correct policies?
6. What is the UX flow when onDisableRequested fires? Is it clear to 
   the user that they need the trusted person's password?

[PASTE GuardianDeviceAdmin.kt AND device_admin.xml]
```

---

## 5. FLUTTER / DART SPECIFIC PROMPTS

---

### 5.1 — Riverpod Provider Audit

```
Audit these Riverpod providers for Guardian (Flutter 3.x, Riverpod 2.x).

Guardian's provider rules:
- protection_provider.dart: VPN / Admin / Accessibility live status
- streak_provider.dart: current streak days + streak history
- config_provider.dart: GuardianConfig from flutter_secure_storage

Check:
1. Are all providers using the correct Riverpod 2.x syntax?
   (AsyncNotifier, Notifier, StreamProvider — not old StateNotifier)
2. Is ref.watch used ONLY in widget build() methods?
   Is ref.read used ONLY in callbacks and outside build()?
3. Are any providers creating new objects on every call (causing rebuilds)?
4. Is AsyncValue.when() handling loading, data, AND error everywhere it's used?
5. Are providers that depend on platform channel calls handling 
   PlatformException separately from null returns?
6. Is there a provider that polls protection layer status?
   If yes, what is the polling interval and is it too aggressive?
7. Are any providers leaking state after Guardian is disabled?

[PASTE PROVIDER FILES]
```

---

### 5.2 — GoRouter Auth Guard Check

```
Review these GoRouter routes for Guardian.

Guardian's routing rules:
- If not set up (no config in secure_storage) → force to /onboarding
- If set up → allow /dashboard, /challenge, /analytics, /emergency
- /settings requires password verification before entry
- /block-overlay is launched by Kotlin, not Flutter router
- No route should be reachable if Device Admin is not active

Check:
1. Is there a redirect guard that checks setup status on every route change?
2. Can a user navigate to /settings without password verification by 
   manipulating the URL or deep link?
3. Is the /onboarding route locked to sequential steps?
   (user should not be able to jump from step 2 to step 5)
4. What happens if the app is backgrounded on /emergency and 
   then brought back — does it restore correctly?
5. Are any routes accessible while Guardian is in a "partially set up" 
   state (e.g., VPN started but Device Admin not yet activated)?

[PASTE app.dart WITH GoRouter CONFIG]
```

---

### 5.3 — Streak Logic Audit

```
Audit Guardian's streak tracking logic.

Rules:
- A streak starts on the day the user first sets up Guardian
- A streak day counts only if no manual reset was triggered that day
- A relapse resets the streak to 0 and creates a new StreakRecord in Room DB
- The current streak is the most recent StreakRecord where endDate is null
- The 21-Day Challenge uses this same streak data

Check:
1. Is the streak calculated from the DB correctly for day boundaries?
   (midnight rollover in the user's local timezone — not UTC)
2. What happens if the user's phone clock is changed manually?
3. What if the user hasn't opened the app for 5 days — does the 
   streak continue correctly or does it show 0?
4. Is a relapse logged atomically? (close current streak AND start new one)
5. What happens if the app crashes during a relapse write?
6. Does the 21-Day Challenge progress correctly after a relapse and restart?

[PASTE streak_service.dart AND streak_provider.dart]
```

---

## 6. KOTLIN / ANDROID SPECIFIC PROMPTS

---

### 6.1 — AndroidManifest Permissions Audit

```
Audit this AndroidManifest.xml for Guardian.

Required permissions and their justification:
- BIND_VPN_SERVICE → Layer 1 VPN
- BIND_ACCESSIBILITY_SERVICE → Layer 2 URL monitoring
- BIND_DEVICE_ADMIN → Layer 4 anti-uninstall
- RECEIVE_BOOT_COMPLETED → service restart on boot
- FOREGROUND_SERVICE → VPN foreground service
- FOREGROUND_SERVICE_DATA_SYNC → background classification
- FOREGROUND_SERVICE_MEDIA_PROJECTION → Layer 3 screen capture
- INTERNET + ACCESS_NETWORK_STATE → VPN tunnel
- REQUEST_IGNORE_BATTERY_OPTIMIZATIONS → prevent service kills

Check:
1. Are all 4 service declarations present with correct intent-filter actions?
2. Is the DeviceAdminReceiver declared with android:permission="BIND_DEVICE_ADMIN"?
3. Are the res/xml/ references correct for device_admin.xml and accessibility_config.xml?
4. Is android:exported set correctly for each component?
   (services that need system binding must be exported)
5. Are there any permissions declared that Guardian does NOT actually need?
   (minimal permissions principle)
6. Is the targetSdk and compileSdk correct for all APIs Guardian uses?
   (MediaProjection behavior changed in Android 14)
7. Is the foreground service type declared for each ForegroundService 
   that uses a different type? (Android 14 requirement)

[PASTE AndroidManifest.xml]
```

---

### 6.2 — Service Lifecycle Audit

```
Check the lifecycle handling across all Guardian Android services.

Services:
- GuardianVpnService (VpnService, Foreground, START_STICKY)
- GuardianAccessibilityService (AccessibilityService, system-managed)
- BootReceiver (BroadcastReceiver, BOOT_COMPLETED)
- ScreenAnalyzer (WorkManager PeriodicTask)

For each service, verify:
1. Does it have the correct onStartCommand return value (START_STICKY)?
2. Does it handle being killed by the OS and restarted cleanly 
   (intent may be null on restart)?
3. Does the BootReceiver restart ALL services, not just the VPN?
4. Does WorkManager use setRequiresBatteryNotLow() for ScreenAnalyzer?
   (avoid running ML Kit when battery is critical)
5. Does each Foreground Service show a persistent notification?
   Is the notification channel created before startForeground()?
6. On Android 12+, is the exact alarm permission declared for any 
   scheduled tasks? (WorkManager should handle this, but verify)
7. What is the total battery impact of all 4 services running simultaneously?
   Provide a rough estimate.

[PASTE ALL SERVICE FILES]
```

---

## 7. SECURITY & PASSWORD SYSTEM PROMPTS

---

### 7.1 — Password System Full Audit

```
Perform a complete security audit of Guardian's password system.

Guardian password rules:
- SHA-256 hash only — plain text NEVER stored anywhere
- Hashed in Kotlin using MessageDigest("SHA-256")
- Stored in flutter_secure_storage under key "guardian_password_hash"
- Shown in plain text ONCE in the handoff dialog, then discarded
- No "forgot password" flow — by design
- Verified by Kotlin via "verifyPassword" platform channel method

Audit every touchpoint:
1. Is there any code path where the plain text password could be logged,
   stored in SharedPreferences, or sent anywhere?
2. Is SHA-256 being computed correctly? 
   (encoding matters: use UTF-8, not default platform encoding)
3. Is the secure storage key consistent across all files?
   (a typo in the key name would silently fail verification)
4. Is the handoff dialog dismissible in a way that might re-show the password?
5. Is there any implicit backup (Android Auto Backup) that could 
   accidentally backup the hashed password to Google Drive?
   If yes, add android:allowBackup="false" or exclude the key.
6. Is the password verification method timing-safe?
   (constant-time comparison, not String equality)
7. After the handoff dialog is dismissed, is the plain text password 
   cleared from memory (not just unreferenced)?

[PASTE: password_hasher.dart, secure_storage.dart, 
        set_password_screen.dart, password_handoff_screen.dart,
        GuardianVpnService.kt password verification block]
```

---

### 7.2 — Bypass Route Hunt

```
You are a penetration tester trying to bypass Guardian's protection.
Guardian's goal: make it impossible for the user to access adult content,
even if they are actively trying to bypass it in a moment of weakness.

Protection layers:
1. VPN DNS filtering (Room DB, 100k domains, Cloudflare Family DNS upstream)
2. Accessibility Service URL + keyword monitor
3. ML Kit screen analysis every 5 minutes
4. Device Admin anti-uninstall (password required to deactivate)

Find every realistic bypass route a non-technical user could attempt:

1. NETWORK BYPASSES — How could someone get past the DNS filter?
   (VPN off, different DNS, HTTPS direct IP, Tor, another VPN app, etc.)

2. APP BYPASSES — How could someone get content without a browser?
   (private app stores, APK sideloading, incognito modes, etc.)

3. SYSTEM BYPASSES — How could someone disable Guardian's services?
   (safe mode, ADB, factory reset, second user profile, etc.)

4. SOCIAL ENGINEERING — How could someone manipulate the trusted person 
   into giving up the password?

For each bypass:
- SEVERITY: Critical / High / Medium / Low
- CAN GUARDIAN CLOSE THIS? Yes / Partially / No
- MITIGATION: What code or UX change would close it?

Be brutal. The whole app's purpose depends on this being airtight.
```

---

## 8. BUG DIAGNOSIS PROMPTS

---

### 8.1 — Service Crash Diagnosis

```
A Guardian Android service crashed in production. Help me diagnose it.

Service that crashed: [GuardianVpnService / GuardianAccessibilityService / 
                       GuardianDeviceAdmin / ScreenAnalyzer]

Symptoms: [DESCRIBE WHAT THE USER EXPERIENCED]

Logcat output:
[PASTE LOGCAT HERE]

Device info: [ANDROID VERSION, DEVICE MANUFACTURER]

Diagnose:
1. ROOT CAUSE — what exactly caused the crash?
2. TRIGGER — what sequence of events led to this?
3. IS THIS MANUFACTURER-SPECIFIC? 
   (Samsung, Xiaomi, OnePlus all aggressively kill background services)
4. FIX — exact code change needed
5. PREVENTION — what guard should I add to prevent this class of crash?
6. DID THIS LEAVE GUARDIAN UNPROTECTED? 
   If yes, for how long, and how do I detect this state?
```

---

### 8.2 — Block Not Triggering

```
Guardian is NOT blocking content it should block. Help me trace the failure.

What should have been blocked: [URL / keyword / screen content]
Which layer should have caught it: [VPN / Accessibility / MLKit / unknown]

Diagnosis trace:
1. LAYER 1 (VPN): Is the domain in the Room DB blocklist?
   Query: SELECT * FROM blocked_domains WHERE domain = '[domain]'
   If missing → blocklist gap, not a code bug.

2. LAYER 2 (Accessibility): Was the URL visible in the accessibility tree?
   Ask me to paste the accessibility tree dump if needed.
   Is the keyword in ADULT_KEYWORDS?

3. LAYER 3 (MLKit): Is WorkManager actually running?
   What was the confidence score for the relevant label?

4. GENERAL: Is the VPN service running? Is Accessibility enabled?
   Is Device Admin active? All 3 must be true.

Based on my description: [DESCRIBE WHAT HAPPENED IN DETAIL]

Tell me exactly which layer failed and why, and what code or 
data fix will close this gap.
```

---

### 8.3 — Streak Data Corruption

```
Guardian's streak data is wrong. Help me find the corruption.

Symptom: [e.g., "streak shows 0 after phone restart" / 
          "21-Day Challenge shows wrong day" / 
          "relapse logged but streak didn't reset"]

Relevant code:
[PASTE streak_service.dart]
[PASTE streak_provider.dart]

Debug:
1. Is the Room DB query returning the correct "active" streak?
   (endDate IS NULL = active, endDate IS NOT NULL = historical)
2. Is timezone handling correct?
   (totalDays calculation must use local time, not UTC)
3. Is the Riverpod provider invalidating and re-reading after a streak reset?
4. Is the block overlay logging a relapse when it should only log an attempt?
   (seeing the block ≠ relapsing — they are different events)
5. Write a corrected version of the broken logic.
```

---

## 9. TESTING PROMPTS

---

### 9.1 — Unit Test Generator

```
Write unit tests for this Guardian [Dart / Kotlin] code.

Testing framework: [flutter_test + mocktail for Dart / JUnit4 + Mockito for Kotlin]

For each test:
- Test the BEHAVIOR, not the implementation
- Cover the happy path, the null/empty path, and the failure path
- For anything touching flutter_secure_storage: mock it
- For anything touching Room DB: use an in-memory database
- For Platform Channels in Dart tests: mock the MethodChannel

Specifically test:
1. Password hash correctness (SHA-256 output matches known test vector)
2. Domain lookup returns true for known adult domain, false for google.com
3. Streak day calculation is correct across midnight boundary (local timezone)
4. verifyPassword returns false for wrong password, true for correct one
5. Block attempt is logged correctly after overlay is shown
6. [ANY ADDITIONAL BEHAVIORS SPECIFIC TO YOUR FEATURE]

[PASTE CODE TO TEST]
```

---

### 9.2 — Real Device QA Checklist Generator

```
Generate a manual QA checklist for testing this Guardian feature on a real device.

Feature being tested: [FEATURE NAME]
Device to test on: [ANDROID VERSION + MANUFACTURER]

The checklist must cover:

SETUP STATE TESTS:
□ Test with Guardian fully set up (all 4 layers active)
□ Test with VPN running but Accessibility disabled
□ Test with phone freshly rebooted
□ Test after app force-stop

BLOCKING TESTS:
□ Test that [CONTENT TYPE] is blocked within [X seconds]
□ Test that block overlay appears and cannot be dismissed early
□ Test that block attempt is logged to the DB

PERSISTENCE TESTS:
□ Force-stop the app → services still running?
□ Reboot the phone → services auto-restart?
□ Enable battery saver mode → services still alive?

SECURITY TESTS:
□ Try to uninstall without password → blocked?
□ Try to disable Accessibility from Settings → warning shown?
□ Try to turn off VPN from Quick Settings tile → Lockdown Mode cuts internet?

STREAK TESTS:
□ Streak day count correct after midnight?
□ Block attempt does NOT reset streak?

Include pass/fail columns and expected behavior for each item.
```

---

## 10. REFACTOR PROMPTS

---

### 10.1 — Code Smell Hunter

```
Review this Guardian code for code smells and architecture violations.

Guardian's architecture rules:
- Flutter: screens only call providers/services, never platform channels directly
- All platform channel calls go through protection_service.dart
- All DB operations go through Room DAOs, never raw SQL in service files
- All password operations go through password_hasher.dart
- Kotlin services must not hold references to Activity contexts (use applicationContext)
- No logic in UI widgets — widgets are display-only, logic in providers

Find:
1. Any screen calling MethodChannel directly (should go through protection_service.dart)
2. Any raw SQL outside of DAO files
3. Any password comparison happening outside password_hasher.dart
4. Any Activity context stored in a service or ViewModel
5. Any business logic inside a Flutter widget's build() method
6. Any hardcoded strings that should be in constants.dart

For each smell: show the bad code, show the correct version, 
and explain which architectural rule it violates.

[PASTE CODE]
```

---

### 10.2 — Kotlin Service Modernizer

```
Modernize this Guardian Kotlin service to use modern Android patterns.

Target: Android API 26+ minimum (check Guardian's minSdk)
Patterns to apply where missing:
- Coroutines + Flow instead of callbacks for async DB operations
- viewModelScope / lifecycleScope where applicable
- Hilt injection if Guardian uses it (check build.gradle)
- @Volatile for fields shared between threads in services
- Structured concurrency — no GlobalScope.launch
- StateFlow instead of LiveData for reactive state

Check specifically:
1. Are Room DB calls inside Dispatchers.IO? Not on Main thread?
2. Is the VPN packet processing on a dedicated thread with correct priority?
3. Are there any memory leaks from context references held in services?
4. Is the foreground service notification using NotificationCompat 
   (not the deprecated Notification.Builder)?

Show before and after for each modernization.

[PASTE KOTLIN SERVICE FILE]
```

---

## 11. PERFORMANCE PROMPTS

---

### 11.1 — Battery Impact Audit

```
Audit Guardian's battery impact. This app runs 4 persistent services 
simultaneously. It must be invisible to the user in terms of battery drain.

Services:
1. GuardianVpnService — foreground, always-on VPN tunnel
2. GuardianAccessibilityService — monitoring every accessibility event
3. ScreenAnalyzer — WorkManager, every 5 minutes, ML Kit inference
4. BootReceiver — one-time broadcast, low impact

For each service:
1. ESTIMATED BATTERY IMPACT — mAh/hour rough estimate
2. WORST CASE TRIGGER — what user action makes this service work hardest?
3. OPTIMIZATION — one concrete change that would reduce battery use 
   without reducing protection effectiveness

Then check:
- Is the AccessibilityService debouncing events? 
  (TYPE_WINDOW_CONTENT_CHANGED fires 100s of times/second — 
   checking the blocklist on every event would drain battery instantly)
- Is ML Kit inference scaled to screen-on state only?
- Is the Room DB blocklist query O(log n) via the domain index?
- Are there any wake locks being held unnecessarily?

[PASTE SERVICE FILES]
```

---

### 11.2 — Room DB Query Optimizer

```
Optimize these Guardian Room DB queries for performance.

Context:
- blocked_domains table: 100,000+ rows, indexed on `domain` column
- block_attempts table: grows over time, no row limit
- These queries run on the critical path (VPN packet processing)

For each query:
1. Show the EXPLAIN QUERY PLAN output (if available) or analyze manually
2. Is the index being used? Or is it doing a full table scan?
3. For the analytics queries (weekly/monthly aggregates), 
   should results be cached or pre-computed?
4. Is there any query that should be replaced with a bloom filter 
   for the hot path (DNS packet processing)?

Specifically review:
- The domain lookup query in BlockedDomainDao
- The block attempt insert query
- The streak query (WHERE end_date IS NULL)
- Any GROUP BY or COUNT query used in the analytics screen

[PASTE DAO FILES]
```

---

## 12. UX & RECOVERY FLOW PROMPTS

---

### 12.1 — Emergency Screen UX Audit

```
Review Guardian's Emergency / Urge Surfing screen from a behavioral psychology perspective.

Guardian's emergency screen purpose:
- User is in active distress / urge state
- They pressed "I'm struggling" or the block overlay sent them here
- Goal: keep them engaged for 10+ minutes until the urge passes
- Tools: 4-7-8 breathing (Lottie animation), 10-min movement timer, 
  "read your why" (Day 1 journal), call/SMS accountability person

Review:
1. Is the UI calm and grounding, or is it visually stimulating/stressful?
   (high contrast, fast animations, bright colors = BAD for this context)
2. Is the breathing animation the FIRST thing shown? 
   (breathing exercise works best when started immediately)
3. Is the "call accountability person" button prominent enough?
   (most critical intervention, should not be buried)
4. Is the "read your why" content shown in a way that creates emotional impact?
   (not just a small text block — this should feel significant)
5. Is there a way to accidentally leave this screen quickly?
   (the back button should show a confirmation, not exit instantly)
6. Does the 10-second countdown on the exit button serve its purpose?
   (adding friction = good, but is 10 seconds the right amount?)

Suggest 3 concrete UX improvements backed by behavioral psychology research.

[PASTE emergency_screen.dart]
```

---

### 12.2 — Onboarding Completion Rate Review

```
Review Guardian's onboarding flow for drop-off risks.

The 7 onboarding steps require:
- Step 3: User must grant Device Admin (Android system dialog — scary)
- Step 4: User must start VPN (Android VPN permission dialog)
- Step 5: User must enable Accessibility (requires navigating Settings)
- Step 6: User must trust another person with their password

These are HIGH friction steps. Many users will abandon here.

Review:
1. Does each step EXPLAIN WHY before asking for the permission?
   ("Guardian needs Accessibility to catch content in all your browsers" 
   is better than just launching the Settings screen)
2. Is there a "this is scary, here's why it's safe" reassurance for 
   Device Admin? (users fear this permission because it sounds dangerous)
3. Is the password handoff explained in a way that doesn't create 
   shame or embarrassment? (the user is asking for help — honor that)
4. If a user quits mid-onboarding and comes back, do they resume 
   at the right step or start over?
5. What is the minimum viable setup? (e.g., if user skips ML Kit, 
   do they still get 80% of the protection?)

[PASTE onboarding screens]
```

---

## 13. PRE-COMMIT FINAL CHECK

Run this before EVERY git commit. No exceptions.

---

### 13.1 — Pre-Commit Checklist Prompt

```
I am about to commit this code to Guardian. Run a pre-commit check.

Files changed: [LIST FILES]

BLOCKERS (do not commit if any of these are true):
□ Any hardcoded password or test credentials?
□ Any System.out.println() or print() debug statements?
□ Any TODO comment in logic code (UI copy TODOs are okay)?
□ Any platform channel method call without try/catch PlatformException?
□ Any password comparison using == or .equals() instead of the hasher?
□ Any DB write NOT wrapped in a suspend function or IO dispatcher?
□ Any service that lost its START_STICKY return?
□ Any new permission added to AndroidManifest without justification comment?

WARNINGS (fix before next commit):
□ Any magic number that should be a named constant?
□ Any error state that shows a generic message instead of a specific one?
□ Any missing AsyncValue error handling in a .when() call?
□ Any new string literal that should be in constants.dart?

Run through the above and return:
COMMIT SAFE: Yes / No
BLOCKERS FOUND: [list]
WARNINGS FOUND: [list]

[PASTE CHANGED FILES]
```

---

## 14. WEEKLY CODEBASE HEALTH CHECK

Run this once per week on Sunday before you start the new week.

---

### 14.1 — Weekly Health Check Prompt

```
Perform a weekly health check on the Guardian codebase.

I'll paste the files that changed this week.

Check:

1. ARCHITECTURE DRIFT
   - Are any new screens calling platform channels directly?
     (should go through protection_service.dart)
   - Did any Riverpod providers get created that duplicate existing ones?
   - Did any new DB operations land outside of DAO files?

2. PROTECTION LAYER INTEGRITY
   - Are all 4 protection layers still independently functional?
   - Did any change this week create a dependency between layers 
     that didn't exist before? (layers must be independent)

3. DEAD CODE
   - Are there any methods added this week that are never called?
   - Any platform channel methods defined in Kotlin but not declared in Dart?
   - Any Riverpod providers declared but not used in any widget?

4. TEST COVERAGE GAP
   - What new business logic was added this week with no test?
   - Which of those untested paths is highest risk?

5. BUILD ORDER PROGRESS
   Based on the 4-week build roadmap in CONTEXT.md, where are we?
   - What was completed this week?
   - What is the most important thing to build FIRST next week?
   - Is there any blocker I should resolve before continuing?

[PASTE ALL FILES CHANGED THIS WEEK]
```

---

## APPENDIX — GUARDIAN PROJECT CONSTANTS

Quick reference for AI context. Always include this when asking for code generation.

```
App name: Guardian
Platform channel: guardian/protection
Flutter state: Riverpod 2.x (AsyncNotifier pattern)
Navigation: GoRouter
Local DB: Room (SQLite), Kotlin side only
Secure storage key — password hash: guardian_password_hash
Secure storage key — config: guardian_config
Password hashing: SHA-256, UTF-8 encoding
Blocklist size: 100,000+ domains
Blocklist source: StevenBlack/hosts + oisd.nl
Cloudflare Family DNS: 1.1.1.3 (primary), 1.0.0.3 (secondary)
ML Kit confidence threshold: 75%
Screen analyzer interval: 5 minutes (WorkManager)
Block overlay countdown: 10 seconds
Onboarding steps: 7
Build schedule: 4 weeks (see CONTEXT.md §17)
```

---

*Last updated: Project kickoff — update this file as new patterns emerge.*
*Every prompt here exists to serve one question: Does this make it harder to slip?*