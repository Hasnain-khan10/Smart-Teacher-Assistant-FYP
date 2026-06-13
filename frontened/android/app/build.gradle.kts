plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Sahi namespace jo aapke naye package name se match karta hai
    namespace = "com.hasnain.smartassistant"

    // Aapke Android Studio ke mutabik API 36 aur NDK 28 set kar diya hai
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // FIXED: Application ID ko ab "google-services.json" se 100% match kar diya hai
        applicationId = "com.hasnain.smartassistant"

        minSdk = flutter.minSdkVersion

        // Target SDK ko bhi 36 kar diya hai
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// 🔥 ADDED: Native Android core dependency taake pehli dafa run par hardware logo skip na kare
dependencies {
    implementation("androidx.core:core-splashscreen:1.0.1")
}