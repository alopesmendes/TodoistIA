# AGP 9 KMP Module Restructuring

**Extracted:** 2026-03-13
**Context:** Upgrading AGP 8.x → 9.x in a KMP project with Android targets

## Problem

AGP 9 forbids `com.android.application` or `com.android.library` coexisting with `org.jetbrains.kotlin.multiplatform` in the same Gradle subproject. The top-level `android {}` block is also no longer valid in KMP modules.

## Solution

1. Create a new `:androidApp` module with only `com.android.application` — move `MainActivity`, `AndroidManifest.xml`, and `res/` there.
2. Replace `com.android.library` / `com.android.application` in KMP modules with `com.android.kotlin.multiplatform.library`.
3. Remove `androidTarget {}` + top-level `android {}` block from KMP modules.
4. Add `androidLibrary {}` inside `kotlin {}` with `namespace`, `compileSdk`, `minSdk`, `compilerOptions`.
5. If the module has `res/` files, add `androidResources { enable = true }`.
6. Replace `debugImplementation(...)` with `"androidRuntimeClasspath"(...)`.
7. Move `applicationId`, `versionCode`, `targetSdk`, `packaging`, `buildTypes` to the new `:androidApp` module only.
8. Ensure each module has a **unique namespace** — rename the KMP library's namespace (e.g. `com.ailtontech.todoistia.compose`) to avoid a manifest merger collision with the app module.

## Example

### shared/build.gradle.kts (after)

```kotlin
plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.androidKmpLibrary)   // replaces androidLibrary
}

kotlin {
    androidLibrary {                        // replaces androidTarget{} + android{}
        namespace = "com.example.shared"
        compileSdk = 36
        minSdk = 24
        compilerOptions { jvmTarget.set(JvmTarget.JVM_11) }
    }
    // other targets...
}
```

### androidApp/build.gradle.kts (new module)

```kotlin
plugins {
    alias(libs.plugins.androidApplication)
}

android {
    namespace = "com.example.app"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 24
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}

dependencies {
    implementation(projects.composeApp)
}
```

## When to Use

- Any time AGP is bumped from 8.x → 9.x in a KMP project that has Android targets
- When creating new KMP modules with AGP 9+ from scratch
- When transitioning from a monolithic Android app to a KMP-based multiplatform structure

## Related Changes

- Root `build.gradle.kts` must add plugin entry: `alias(libs.plugins.androidKmpLibrary) apply false`
- `settings.gradle.kts` must add: `include(":androidApp")`
- `gradle/libs.versions.toml` must define: `androidKmpLibrary` plugin version alongside AGP