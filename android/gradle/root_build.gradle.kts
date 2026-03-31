// android/build.gradle.kts  (the ROOT-level one, not app-level)
// ADD the KSP plugin line to your existing plugins block

plugins {
    id("com.google.devtools.ksp") version "1.9.22-1.0.17" apply false
}
// Leave everything else in your android/build.gradle.kts as-is.
// Just add the ksp line above to whatever plugins{} block already exists there.
