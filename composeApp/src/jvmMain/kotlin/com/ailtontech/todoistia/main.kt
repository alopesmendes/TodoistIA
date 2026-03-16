@file:Suppress("ktlint:standard:filename") // Entry point — lowercase `main.kt` is the conventional name

package com.ailtontech.todoistia

import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application

fun main() = application {
    Window(
        onCloseRequest = ::exitApplication,
        title = "TodoistIA",
    ) {
        App()
    }
}
