// android/app/build.gradle.kts
// REPLACE the entire contents of android/app/build.gradle.kts with this

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.devtools.ksp") version "1.9.22-1.0.17"
}

android {
    namespace = "com.example.guardian"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.guardian"
        minSdk = 26  // FIXED: was flutter.minSdkVersion — must be 26+ for all Guardian APIs
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Room DB — all layers persist to local SQLite
    implementation("androidx.room:room-runtime:2.6.1")
    implementation("androidx.room:room-ktx:2.6.1")
    ksp("androidx.room:room-compiler:2.6.1")

    // WorkManager — Layer 3 ScreenAnalyzer scheduling
    implementation("androidx.work:work-runtime-ktx:2.9.0")

    // ML Kit — Layer 3 on-device image labeling
    implementation("com.google.mlkit:image-labeling:17.0.9")

    // Coroutines — async DB + VPN loop
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-tasks:1.7.3")

    // Core AndroidX
    implementation("androidx.core:core-ktx:1.12.0")
}
