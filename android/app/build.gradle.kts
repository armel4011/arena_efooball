import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // PHASE 10 — Firebase Messaging.
    id("com.google.gms.google-services")
}

// Charge `android/key.properties` quand il existe. C'est là que vivent
// les credentials de signature release (jamais commités). Si le fichier
// est absent, le build release retombe sur la config debug — utile en
// dev pour `flutter build apk --release` sans avoir à gérer un keystore.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) {
        load(FileInputStream(f))
    }
}
val hasReleaseKey = keystoreProperties.getProperty("storeFile")?.isNotBlank() == true

android {
    namespace = "com.arena.arena"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (PHASE 10) — backports
        // java.time and other Java 8+ APIs to the Android minSdk.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.arena.arena"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "app"

    productFlavors {
        create("user") {
            dimension = "app"
            applicationId = "com.arena.app"
            resValue("string", "app_name", "ARENA")
        }
        create("admin") {
            dimension = "app"
            applicationId = "com.arena.admin"
            resValue("string", "app_name", "ARENA Admin")
        }
    }

    signingConfigs {
        // `release` n'est défini que si key.properties est présent ET
        // contient un storeFile. Évite de planter le build sur une
        // machine de dev qui n'a pas (encore) le keystore.
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // Vraie signature release si key.properties dispo, sinon
            // fallback sur debug — l'APK reste installable mais ne sera
            // PAS publiable sur le Play Store.
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
