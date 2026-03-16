@file:Suppress("ktlint:standard:filename") // Entry point — lowercase `main.kt` is the conventional name

package com.ailtontech.todoistia

import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.window.ComposeViewport

@OptIn(ExperimentalComposeUiApi::class)
fun main() {
    ComposeViewport {
        App()
    }
}
