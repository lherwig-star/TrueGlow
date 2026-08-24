pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
    // Liest android/app/google-services.json (siehe SETUP.md, Abschnitt 2).
    id("com.google.gms.google-services") version "4.4.3" apply false
    // Laedt die R8-Mapping-Datei zu Crashlytics hoch – ohne sie sind
    // Release-Stacktraces unlesbar.
    id("com.google.firebase.crashlytics") version "3.0.6" apply false
}

include(":app")
