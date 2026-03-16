@file:Suppress("ktlint:standard:function-naming") // iOS factory — PascalCase required by Kotlin/Native convention

package com.ailtontech.todoistia

import androidx.compose.ui.window.ComposeUIViewController

fun MainViewController() = ComposeUIViewController { App() }
