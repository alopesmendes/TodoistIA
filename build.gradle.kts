plugins {
    // this is necessary to avoid the plugins to be loaded multiple times
    // in each subproject's classloader
    alias(libs.plugins.androidApplication) apply false
    alias(libs.plugins.androidLibrary) apply false
    alias(libs.plugins.composeHotReload) apply false
    alias(libs.plugins.composeMultiplatform) apply false
    alias(libs.plugins.composeCompiler) apply false
    alias(libs.plugins.kotlinJvm) apply false
    alias(libs.plugins.kotlinMultiplatform) apply false
    alias(libs.plugins.ktor) apply false
}

tasks.register<Exec>("installGitHooks") {
    group = "setup"
    description = "Installs git hooks from scripts/git-hooks/"
    commandLine("bash", "scripts/git-hooks/install-hooks.sh")
}

tasks.named("prepareKotlinBuildScriptModel") {
    dependsOn("installGitHooks")
}