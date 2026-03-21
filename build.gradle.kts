import org.jlleitschuh.gradle.ktlint.reporter.ReporterType
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
fun env(key: String, default: String = ""): String = System.getenv(key) ?: envVars[key] ?: default

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
    alias(libs.plugins.ktlint)
    alias(libs.plugins.detekt) apply false
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
        nuspecEnabled = false
        nugetconfEnabled = false
        setNodeEnabled(false)
        nodeAudit { enabled = false }
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

// ── ktlint ───────────────────────────────────────────────────────────────────
allprojects {
    apply(plugin = "org.jlleitschuh.gradle.ktlint")

    configure<org.jlleitschuh.gradle.ktlint.KtlintExtension> {
        version.set("1.6.0")
        android.set(true)
        outputToConsole.set(true)
        ignoreFailures.set(false)
        enableExperimentalRules.set(true)
        reporters {
            reporter(ReporterType.HTML)
            reporter(ReporterType.JSON)
            reporter(ReporterType.SARIF)
        }
        filter {
            exclude("**/build/**")
            exclude("**/generated/**")
        }
    }
}

tasks.register("lintCheck") {
    group = "verification"
    description = "Runs ktlint check on all modules"
    dependsOn(subprojects.map { "${it.path}:ktlintCheck" })
}

tasks.register("lintFormat") {
    group = "formatting"
    description = "Runs ktlint format on all modules"
    dependsOn(subprojects.map { "${it.path}:ktlintFormat" })
}

// ── detekt (static analysis) ─────────────────────────────────────────────────
val detektBaseConfig = file(".detekt/detekt-base.yml")
val detektComposeConfig = file(".detekt/detekt-compose.yml")

val composeModules = setOf("composeApp", "androidApp")

allprojects {
    apply(plugin = "io.gitlab.arturbosch.detekt")

    configure<io.gitlab.arturbosch.detekt.extensions.DetektExtension> {
        buildUponDefaultConfig = true
        allRules = false
        parallel = true

        config.setFrom(
            if (project.name in composeModules) {
                listOf(detektBaseConfig, detektComposeConfig)
            } else {
                listOf(detektBaseConfig)
            },
        )
    }

    tasks.withType<io.gitlab.arturbosch.detekt.Detekt>().configureEach {
        reports {
            html.required.set(true)
            sarif.required.set(true)
        }
    }
}

subprojects {
    if (name in composeModules) {
        val detektComposeRulesVersion = rootProject.extensions
            .getByType<VersionCatalogsExtension>()
            .named("libs")
            .findVersion("detekt-compose-rules")
            .get()
            .requiredVersion
        dependencies {
            "detektPlugins"("io.nlopez.compose.rules:detekt:$detektComposeRulesVersion")
        }
    }
}

tasks.register("detektAll") {
    group = "verification"
    description = "Runs detekt on all modules"
    dependsOn(subprojects.map { "${it.path}:detekt" })
}

tasks.register("codeAnalysis") {
    group = "verification"
    description = "Runs all static analysis checks (detekt + ktlint)"
    dependsOn("detektAll", "lintCheck")
}

tasks.register<Exec>("installGitHooks") {
    group = "setup"
    description = "Installs git hooks from scripts/git-hooks/"
    commandLine("bash", "scripts/git-hooks/install-hooks.sh", "--force")
}

tasks.named("prepareKotlinBuildScriptModel") {
    dependsOn("installGitHooks")
}
