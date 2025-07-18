plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services") // ✅ No version here
    id("dev.flutter.flutter-gradle-plugin") // ✅ Flutter plugin must come last
}

dependencies {
    // ✅ Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))

    // ✅ Add Firebase libraries here, e.g.:
    // implementation("com.google.firebase:firebase-analytics")
    // implementation("com.google.firebase:firebase-auth")
}


android {
    namespace = "com.example.exp_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "29.0.13599879" // Updated to match plugin requirements

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.exp_tracker"
        minSdk = 23 // Updated to match firebase_auth requirements
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
