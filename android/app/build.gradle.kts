import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Muss nach dem Flutter-Plugin stehen.
    id("com.google.gms.google-services")
}

// Signierung: Passwoerter und Keystore-Pfad stehen in android/key.properties,
// die Datei ist ueber .gitignore ausgeschlossen. Anlegen: SETUP.md, 12.1.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hatKeystore = keystorePropertiesFile.exists()
if (hatKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.trueglow.app"
    // Ausdruecklich gesetzt statt aus dem Flutter-Standard uebernommen: Beim
    // Upload prueft Play einen Mindestwert, der sich jaehrlich erhoeht. Steht
    // die Zahl hier, faellt eine Anhebung als bewusste Aenderung auf.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications braucht die neueren java.time-APIs auch
        // auf aelteren Android-Versionen.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.trueglow.app"
        // ML Kit Face Detection und die Kamera-Pipeline setzen API 26 voraus.
        minSdk = 26
        targetSdk = 36
        // Kommt aus pubspec.yaml: versionName = SemVer, versionCode fortlaufend.
        // Schema und Regeln in DECISIONS.md, Abschnitt 24.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Nur anlegen, wenn es die Datei gibt – sonst scheitert schon das
        // Konfigurieren des Projekts, auch bei einem reinen Debug-Build.
        if (hatKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Bewusst kein Rueckfall auf die Debug-Schluessel, wenn der
            // Keystore fehlt: Genau das stand vorher hier und haette einen
            // unbrauchbaren Upload erzeugt. Ohne Konfiguration bricht der
            // Build unten mit einer Anleitung ab.
            if (hatKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }

            // Verkleinert das Bundle und entfernt ungenutzten Code. Die Regeln
            // fuer ML Kit, Hive und Firebase stehen in proguard-rules.pro.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// Bricht Release-Builds ab, solange kein eigener Keystore hinterlegt ist.
//
// Ein debug-signiertes App Bundle lehnt Play ohnehin ab – der Fehler faellt
// dann aber erst nach dem Upload auf. Hier faellt er sofort auf, mit der
// Anleitung dazu.
tasks.matching { it.name.contains("Release") && (it.name.startsWith("assemble") || it.name.startsWith("bundle")) }
    .configureEach {
        doFirst {
            if (!hatKeystore) {
                throw GradleException(
                    """
                    |
                    |Kein Release-Keystore hinterlegt.
                    |
                    |Erwartet wird android/key.properties mit:
                    |  storeFile=C:/pfad/zu/trueglow-release.jks
                    |  storePassword=...
                    |  keyAlias=trueglow
                    |  keyPassword=...
                    |
                    |Anlegen: SETUP.md, Abschnitt 12.1.
                    |Fuer einen Testlauf ohne Keystore: flutter run --debug
                    |
                    """.trimMargin(),
                )
            }
        }
    }

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
