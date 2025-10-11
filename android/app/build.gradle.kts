plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
<<<<<<< HEAD
    namespace = "com.example.smart_travel_weather_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
=======
    namespace = "com.example.my_first_app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"
>>>>>>> cc70f9f126a471c888d29de8763ccab9a1bc6a6a

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

<<<<<<< HEAD
=======
    // Configuration pour le multidex si nécessaire
    defaultConfig.multiDexEnabled = true

>>>>>>> cc70f9f126a471c888d29de8763ccab9a1bc6a6a
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
<<<<<<< HEAD
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.smart_travel_weather_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
=======
        applicationId = "com.example.my_first_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0.0"
        
        // Configuration NDK
        ndk {
            abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a", "x86_64"))
        }
>>>>>>> cc70f9f126a471c888d29de8763ccab9a1bc6a6a
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
