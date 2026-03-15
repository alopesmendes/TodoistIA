import java.util.Properties

/**
 * Loads key=value pairs from [file], skipping blank lines and comments (#).
 * System environment variables always take precedence over file values.
 *
 * @param file The [File] to load
 * @return a [Map] of the names and values of the variables and secrets
 */
fun loadEnvFile(file: File): Map<String, String> {
    if (!file.exists()) return emptyMap()
    val props = Properties()
    file.bufferedReader().use { reader ->
        reader
            .lineSequence()
            .map { it.trim() }
            .filter { it.isNotBlank() && !it.startsWith("#") && it.contains("=") }
            .forEach { line ->
                val (key, value) = line.split("=", limit = 2)
                props[key.trim()] = value.trim()
            }
    }
    return props.entries.associate { (k, v) -> k.toString() to v.toString() }
}

/**
 * Resolves the active environment from the APP_ENV system env var (default: "dev").
 * Loads the matching `.env.{env}` file from the project root.
 * System env vars always win over file-defined values.
 */
fun loadEnv(): Map<String, String> {
    val env = System.getenv("APP_ENV") ?: "dev"
    val envFile = rootProject.file("env/.env.$env")
    val fileValues = loadEnvFile(envFile)
    // System env takes precedence — only inject values not already set
    return fileValues.filterKeys { System.getenv(it) == null }
}

val envVars: Map<String, String> = loadEnv()

/** Resolves a config value: system env → .env file → [default]. */
fun env(
    key: String,
    default: String = "",
): String = System.getenv(key) ?: envVars[key] ?: default

plugins {
    // this is necessary to avoid the plugins to be loaded multiple times
    // in each subproject's classloader
    alias(libs.plugins.androidApplication) apply false
    alias(libs.plugins.androidLibrary) apply false
    alias(libs.plugins.androidKmpLibrary) apply false
    alias(libs.plugins.composeHotReload) apply false
    alias(libs.plugins.composeMultiplatform) apply false
    alias(libs.plugins.composeCompiler) apply false
    alias(libs.plugins.kotlinJvm) apply false
    alias(libs.plugins.kotlinMultiplatform) apply false
    alias(libs.plugins.ktor) apply false
    alias(libs.plugins.owaspDependencyCheck)
    alias(libs.plugins.benManesVersions)
}

// ── OWASP Dependency Check ──────────────────────────────────────────────────
dependencyCheck {
    // Fail build if any dependency has a CVSS score >= 7.0 (high/critical)
    failBuildOnCVSS = 7.0f
    suppressionFile = "dependency-check-suppression.xml"
    formats = listOf("HTML", "SARIF")
    nvd {
        // Resolved from APP_ENV .env file or system environment (e.g. GitHub Secret)
        apiKey = env("NVD_API_KEY")
    }
    analyzers {
        // Disable analyzers not relevant to JVM/KMP projects to speed up scans
        assemblyEnabled = false
        nodeEnabled = false
        nodeAuditEnabled = false
        nuspecEnabled = false
        nugetconfEnabled = false
        retirejs { enabled = false }
    }
}

// ── Ben-Manes Versions (freshness check) ────────────────────────────────────
fun isNonStable(version: String): Boolean {
    val stableKeywords = listOf("RELEASE", "FINAL", "GA")
    val unstableKeywords = listOf("alpha", "beta", "rc", "cr", "m", "preview", "dev", "eap")
    val upperVersion = version.uppercase()
    val isStable = stableKeywords.any { upperVersion.contains(it) } || version.matches(Regex("^[0-9,.v-]+$"))
    val isUnstable = unstableKeywords.any { upperVersion.contains(it.uppercase()) }
    return isUnstable && !isStable
}

tasks.withType<com.github.benmanes.gradle.versions.updates.DependencyUpdatesTask> {
    rejectVersionIf { isNonStable(candidate.version) && !isNonStable(currentVersion) }
    outputFormatter = "json,html"
    outputDir = "build/reports/dependencyUpdates"
    reportfileName = "dependency-updates"
}

tasks.register<Exec>("installGitHooks") {
    group = "setup"
    description = "Installs git hooks from scripts/git-hooks/"
    commandLine("bash", "scripts/git-hooks/install-hooks.sh", "--force")
}

tasks.named("prepareKotlinBuildScriptModel") {
    dependsOn("installGitHooks")
}
