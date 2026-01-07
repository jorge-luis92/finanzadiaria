plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.desarrollochido.finanzadiaria"
    compileSdk = 36  // ← Versión fija
    ndkVersion = "27.0.12077973"  // ← Versión fija

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.desarrollochido.finanzadiaria"
        minSdk = flutter.minSdkVersion  // ← Versión mínima para Play Store
        targetSdk = 36  // ← Última versión
        versionCode = 1
        versionName = "1.0.0"
    }

    // ==== FIRMA MANUAL (sin key.properties) ====
    signingConfigs {
        create("release") {
            // Aquí pones los datos DIRECTAMENTE (temporal)
            storeFile = file("../keystores/finanzas-app.jks")
            storePassword = "App.2024sindrome"
            keyAlias = "upload"
            keyPassword = "App.2024sindrome"
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
