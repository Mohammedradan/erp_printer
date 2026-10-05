import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ─────────────────────────────────────────────────────────────────────────────
// توقيع الإصدار
//
// أنشئ `android/key.properties` (غير مرفوع للمستودع) بهذا الشكل:
//   storePassword=...
//   keyPassword=...
//   keyAlias=matbaa-erp
//   storeFile=/absolute/path/to/matbaa-erp-release.jks
//
// أو مرّر نفس القيم عبر متغيرات البيئة:
//   ERP_STORE_PASSWORD / ERP_KEY_PASSWORD / ERP_KEY_ALIAS / ERP_STORE_FILE
//
// بدون هذا الملف يبقى release بمفتاح debug حتى يعمل `flutter run --release`
// محلياً، لكنه غير صالح للنشر أو التسليم التجاري.
// ─────────────────────────────────────────────────────────────────────────────
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun signingValue(key: String, envKey: String): String? =
    keystoreProperties.getProperty(key) ?: System.getenv(envKey)

val releaseStoreFile = signingValue("storeFile", "ERP_STORE_FILE")
val hasReleaseSigning = !releaseStoreFile.isNullOrBlank() &&
    file(releaseStoreFile!!).exists()

android {
    namespace = "com.example.erp_printer"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.erp_printer"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = signingValue("storePassword", "ERP_STORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "ERP_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "ERP_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // يوقَّع بمفتاح الإنتاج عند توفر key.properties، وإلا بمفتاح debug
            // حتى تبقى builds التطوير تعمل. لا تسلّم نسخة موقعة بمفتاح debug.
            signingConfig = if (hasReleaseSigning) {
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
