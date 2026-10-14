import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
fun hasKeystoreValue(key: String): Boolean {
    return (keystoreProperties[key] as String?)?.isNotBlank() == true
}
val hasReleaseKeystore = keystorePropertiesFile.exists()
        && hasKeystoreValue("keyAlias")
        && hasKeystoreValue("keyPassword")
        && hasKeystoreValue("storeFile")
        && hasKeystoreValue("storePassword")

if (!hasReleaseKeystore) {
    gradle.taskGraph.whenReady {
        if (allTasks.any { it.name.contains("Release", ignoreCase = true) }) {
            throw GradleException("Release signing requires android/key.properties with the upload keystore configuration.")
        }
    }
}

android {
    // Preserve native-library extraction through the supported AGP DSL.
    packaging {
        jniLibs.useLegacyPackaging = true
    }

    namespace = "ge.mili.delivery"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "ge.mili.delivery"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // A Play release must never silently fall back to debug signing.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

project.afterEvaluate {
    val buildDir = project.layout.buildDirectory.get()
    val flutterAssetsDir = "$buildDir/intermediates/flutter/release/flutter_assets"
    val mergeOutputDir = "$buildDir/intermediates/assets/release/mergeReleaseAssets"

    val fixFlutterAssets = project.tasks.register("fixFlutterAssetsRelease", Copy::class.java) {
        dependsOn("compileFlutterBuildRelease")
        dependsOn("mergeReleaseAssets")
        from(flutterAssetsDir)
        into("$mergeOutputDir/flutter_assets")
    }

    project.tasks.findByName("compressReleaseAssets")?.dependsOn(fixFlutterAssets)
    project.tasks.findByName("packageRelease")?.dependsOn(fixFlutterAssets)
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("androidx.core:core:1.17.0")
    implementation("androidx.datastore:datastore-preferences:1.2.1")
    implementation("com.google.firebase:firebase-messaging:23.4.1")
}
