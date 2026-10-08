plugins {
    id("com.android.application")
    id("com.google.devtools.ksp")
    id("dev.flutter.flutter-gradle-plugin")
}

fun quotedBuildConfig(value: String): String =
    "\"${value.replace("\\", "\\\\").replace("\"", "\\\"")}\""

fun environmentFlag(name: String): Boolean =
    when (val value = System.getenv(name)?.trim()?.lowercase()) {
        null, "", "false", "0" -> false
        "true", "1" -> true
        else -> throw GradleException("$name must be true/false or 1/0, not '$value'")
    }

val debugAdsEnabled = environmentFlag("UNUTMA_DEBUG_ADS")
val releaseAdsEnabled = environmentFlag("UNUTMA_ADS_ENABLED")
val releaseAdMobAppId = System.getenv("UNUTMA_ADMOB_APP_ID")?.trim().orEmpty()
val releaseInterstitialId = System.getenv("UNUTMA_ADMOB_INTERSTITIAL_ID")?.trim().orEmpty()
val releaseBannerId = System.getenv("UNUTMA_ADMOB_BANNER_ID")?.trim().orEmpty()
val adMobAppIdPattern = Regex("^ca-app-pub-[0-9]{16}~[0-9]{10}$")
val adMobUnitIdPattern = Regex("^ca-app-pub-[0-9]{16}/[0-9]{10}$")
val googleTestPublisherPrefix = "ca-app-pub-3940256099942544"

if (releaseAdsEnabled) {
    if (!adMobAppIdPattern.matches(releaseAdMobAppId)) {
        throw GradleException(
            "UNUTMA_ADMOB_APP_ID is required when UNUTMA_ADS_ENABLED=true",
        )
    }
    if (!adMobUnitIdPattern.matches(releaseInterstitialId)) {
        throw GradleException(
            "UNUTMA_ADMOB_INTERSTITIAL_ID is required when UNUTMA_ADS_ENABLED=true",
        )
    }
    if (!adMobUnitIdPattern.matches(releaseBannerId)) {
        throw GradleException(
            "UNUTMA_ADMOB_BANNER_ID is required when UNUTMA_ADS_ENABLED=true",
        )
    }
    if (
        releaseAdMobAppId.startsWith(googleTestPublisherPrefix) ||
        releaseInterstitialId.startsWith(googleTestPublisherPrefix) ||
        releaseBannerId.startsWith(googleTestPublisherPrefix)
    ) {
        throw GradleException("Google test AdMob IDs cannot be used in an ad-enabled release build")
    }
}

android {
    namespace = "app.unutma.unutma"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig {
        // Google Play package identity. Never change this after the first upload.
        applicationId = "app.unutma.mobile"
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        manifestPlaceholders["ADMOB_APP_ID"] = ""
    }
    buildFeatures { buildConfig = true }
    val signingValues = mapOf(
        "UNUTMA_KEYSTORE" to System.getenv("UNUTMA_KEYSTORE"),
        "UNUTMA_STORE_PASSWORD" to System.getenv("UNUTMA_STORE_PASSWORD"),
        "UNUTMA_KEY_ALIAS" to System.getenv("UNUTMA_KEY_ALIAS"),
        "UNUTMA_KEY_PASSWORD" to System.getenv("UNUTMA_KEY_PASSWORD"),
    )
    val configuredSigningValues = signingValues.filterValues { !it.isNullOrBlank() }
    if (configuredSigningValues.isNotEmpty() && configuredSigningValues.size != signingValues.size) {
        throw GradleException("Release signing requires all UNUTMA signing environment variables")
    }
    if (configuredSigningValues.size == signingValues.size) {
        signingConfigs.create("production") {
            storeFile = file(signingValues.getValue("UNUTMA_KEYSTORE")!!)
            storePassword = signingValues.getValue("UNUTMA_STORE_PASSWORD")
            keyAlias = signingValues.getValue("UNUTMA_KEY_ALIAS")
            keyPassword = signingValues.getValue("UNUTMA_KEY_PASSWORD")
        }
    }
    buildTypes {
        debug {
            // Google's sample IDs are compiled only into explicitly ad-enabled debug builds.
            manifestPlaceholders["ADMOB_APP_ID"] =
                if (debugAdsEnabled) "ca-app-pub-3940256099942544~3347511713" else ""
            buildConfigField("boolean", "ADS_ENABLED", debugAdsEnabled.toString())
            buildConfigField(
                "String",
                "ADMOB_INTERSTITIAL_ID",
                quotedBuildConfig(
                    if (debugAdsEnabled) "ca-app-pub-3940256099942544/1033173712" else "",
                ),
            )
            buildConfigField(
                "String",
                "ADMOB_BANNER_ID",
                quotedBuildConfig(
                    if (debugAdsEnabled) "ca-app-pub-3940256099942544/6300978111" else "",
                ),
            )
            buildConfigField("boolean", "ADMOB_TEST_ADS", debugAdsEnabled.toString())
        }
        release {
            isDebuggable = false
            signingConfig = signingConfigs.findByName("production")
            manifestPlaceholders["ADMOB_APP_ID"] =
                if (releaseAdsEnabled) releaseAdMobAppId else ""
            buildConfigField("boolean", "ADS_ENABLED", releaseAdsEnabled.toString())
            buildConfigField(
                "String",
                "ADMOB_INTERSTITIAL_ID",
                quotedBuildConfig(if (releaseAdsEnabled) releaseInterstitialId else ""),
            )
            buildConfigField(
                "String",
                "ADMOB_BANNER_ID",
                quotedBuildConfig(if (releaseAdsEnabled) releaseBannerId else ""),
            )
            buildConfigField("boolean", "ADMOB_TEST_ADS", "false")
        }
    }
    testOptions {
        unitTests.isIncludeAndroidResources = false
        unitTests.all {
            // Robolectric's native Conscrypt library lookup must not Turkish-case "windows".
            it.systemProperty("user.language", "en")
            it.systemProperty("user.country", "US")
        }
    }
    sourceSets.getByName("androidTest").assets.srcDir("$projectDir/schemas")
}
kotlin { compilerOptions { jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17 } }
ksp { arg("room.schemaLocation", "$projectDir/schemas") }
dependencies {
    implementation("androidx.room:room-runtime:2.8.4")
    implementation("androidx.room:room-ktx:2.8.4")
    ksp("androidx.room:room-compiler:2.8.4")
    implementation("androidx.work:work-runtime-ktx:2.11.2")
    implementation("androidx.core:core-ktx:1.17.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.16.1")
    testImplementation("androidx.test:core:1.7.0")
    testImplementation("androidx.work:work-testing:2.11.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.10.2")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
    androidTestImplementation("androidx.test:runner:1.7.0")
    androidTestImplementation("androidx.test.uiautomator:uiautomator:2.3.0")
    // Room 2.8.4's schema serializer is compiled against 1.8.1. SavedState's
    // older BOM otherwise mixes json 1.8.1 with core 1.7.3 in debug tests.
    debugImplementation(platform("org.jetbrains.kotlinx:kotlinx-serialization-bom:1.8.1"))
    androidTestImplementation("androidx.room:room-testing:2.8.4")
    androidTestImplementation("androidx.work:work-testing:2.11.2")
}
flutter { source = "../.." }
