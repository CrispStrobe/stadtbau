// SPDX-License-Identifier: AGPL-3.0-or-later
import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing (task T-402).
//
// The upload key never enters the repository. `android/key.properties` and any
// `*.jks` / `*.keystore` are git-ignored; CI writes both from repository secrets
// (see .github/workflows/android-release.yml and docs/release/android.md).
//
// Expected keys in android/key.properties:
//   storeFile=/absolute/path/to/upload-keystore.jks   (relative paths resolve
//                                                      against android/)
//   storePassword=...
//   keyAlias=upload
//   keyPassword=...
//
// When the file is absent -- local development, the `check` workflow, any
// contributor clone -- the release build falls back to the debug key so that
// `flutter build apk --release` and `flutter run --release` keep working. Such
// an artifact is NOT publishable; the release workflow refuses to attach it.
val keystorePropertiesFile: File = rootProject.file("key.properties")
val hasReleaseKeystore: Boolean = keystorePropertiesFile.exists()
val keystoreProperties = Properties()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
} else {
    logger.lifecycle(
        "hectopolis: android/key.properties not found -- release builds are signed with the " +
            "debug key. Such an artifact must not be published.",
    )
}

/** Resolves a path from key.properties: absolute as-is, relative against android/. */
fun keystorePath(value: String): File {
    val candidate = File(value)
    return if (candidate.isAbsolute) candidate else rootProject.file(value)
}

android {
    namespace = "com.crispstrobe.hectopolis"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.crispstrobe.hectopolis"
        // flutter.minSdkVersion is 24 with Flutter 3.44; the plugins in use
        // (shared_preferences_android, url_launcher_android: minSdk 24,
        // package_info_plus: minSdk 19) need no more than that, so no override.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                val storeFilePath = requireNotNull(keystoreProperties.getProperty("storeFile")) {
                    "storeFile missing in ${keystorePropertiesFile.path}"
                }
                storeFile = keystorePath(storeFilePath)
                storePassword = requireNotNull(keystoreProperties.getProperty("storePassword")) {
                    "storePassword missing in ${keystorePropertiesFile.path}"
                }
                keyAlias = requireNotNull(keystoreProperties.getProperty("keyAlias")) {
                    "keyAlias missing in ${keystorePropertiesFile.path}"
                }
                keyPassword = requireNotNull(keystoreProperties.getProperty("keyPassword")) {
                    "keyPassword missing in ${keystorePropertiesFile.path}"
                }
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (hasReleaseKeystore) {
                    signingConfigs.getByName("release")
                } else {
                    signingConfigs.getByName("debug")
                }
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
