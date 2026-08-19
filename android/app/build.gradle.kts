import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. Locally the credentials come from android/key.properties
// (gitignored); in CI they arrive as environment variables decoded from repo
// secrets. When neither is present we fall back to the debug key so that
// `flutter run --release` still works on a fresh checkout.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        keystorePropertiesFile.inputStream().use { load(it) }
    }
}

fun signingValue(propertyKey: String, envKey: String): String? =
    keystoreProperties.getProperty(propertyKey) ?: System.getenv(envKey)

val releaseStoreFilePath = signingValue("storeFile", "WICARA_KEYSTORE_PATH")
val hasReleaseSigning = releaseStoreFilePath != null &&
    rootProject.file(releaseStoreFilePath).exists()

android {
    namespace = "com.example.wicara_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.wicara.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(flutter.minSdkVersion, 23)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                // Generated with openssl, so the store is PKCS12 rather than the
                // JKS that keytool would have produced. AGP will not infer this.
                storeType = "PKCS12"
                storeFile = rootProject.file(releaseStoreFilePath!!)
                storePassword = signingValue("storePassword", "WICARA_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "WICARA_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "WICARA_KEY_PASSWORD")
                // APK Signature Scheme v2 only lands on API 24+. minSdk here is
                // 23, and an APK without the v1 JAR signature fails to install on
                // Android 6.0 -- apksigner --min-sdk-version 23 rejects it
                // outright. AGP does not infer this from minSdk.
                enableV1Signing = true
                enableV2Signing = true
            }
        }
    }

    buildTypes {
        release {
            // Sideloaded builds must keep a stable signature across releases:
            // Android refuses to install an update signed by a different key,
            // and CI regenerates its debug keystore on every run.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    // LiteRT-LM Kotlin API for on-device Gemma runtime.
    implementation("com.google.ai.edge.litertlm:litertlm-android:latest.release")
}

flutter {
    source = "../.."
}
