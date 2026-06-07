import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystorePropertiesFile = rootProject.file("key.properties")
val releaseKeystoreProperties = Properties()
if (releaseKeystorePropertiesFile.exists()) {
    releaseKeystorePropertiesFile.inputStream().use(releaseKeystoreProperties::load)
}

val testAdMobAndroidAppId = "ca-app-pub-3940256099942544~3347511713"

fun releaseKeystoreProperty(name: String): String =
    releaseKeystoreProperties.getProperty(name)
        ?: throw GradleException("Missing $name in android/key.properties")

fun stringPropertyOrEnv(name: String): String =
    (project.findProperty(name) as String?)?.takeIf { it.isNotBlank() }
        ?: providers.environmentVariable(name).orNull?.takeIf { it.isNotBlank() }
        ?: ""

val adMobAndroidAppId = stringPropertyOrEnv("ADMOB_ANDROID_APP_ID")
val authRedirectScheme =
    stringPropertyOrEnv("APP_AUTH_REDIRECT_SCHEME").ifEmpty { "fuelarena" }
val authRedirectHost =
    stringPropertyOrEnv("APP_AUTH_REDIRECT_HOST").ifEmpty { "login-callback" }

android {
    namespace = "com.fuelarena.fuel_arena"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.fuelarena.fuel_arena"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["ADMOB_ANDROID_APP_ID"] =
            adMobAndroidAppId.ifEmpty { testAdMobAndroidAppId }
        manifestPlaceholders["APP_AUTH_REDIRECT_SCHEME"] = authRedirectScheme
        manifestPlaceholders["APP_AUTH_REDIRECT_HOST"] = authRedirectHost
    }

    signingConfigs {
        create("release") {
            if (releaseKeystorePropertiesFile.exists()) {
                keyAlias = releaseKeystoreProperty("keyAlias")
                keyPassword = releaseKeystoreProperty("keyPassword")
                storeFile = file(releaseKeystoreProperty("storeFile"))
                storePassword = releaseKeystoreProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

gradle.taskGraph.whenReady {
    val buildsRelease = allTasks.any { task ->
        task.name.contains("Release", ignoreCase = false)
    }
    if (buildsRelease) {
        val releaseFailures = mutableListOf<String>()
        if (!releaseKeystorePropertiesFile.exists()) {
            releaseFailures +=
                "Release signing requires android/key.properties. " +
                    "Copy android/key.properties.example, fill keystore values, " +
                    "and keep the real file out of git."
        }
        if (adMobAndroidAppId.isBlank() ||
            adMobAndroidAppId == testAdMobAndroidAppId
        ) {
            releaseFailures +=
                "Release builds require a production ADMOB_ANDROID_APP_ID " +
                    "Gradle property or environment variable."
        }
        if (releaseFailures.isNotEmpty()) {
            throw GradleException(releaseFailures.joinToString("\n"))
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
