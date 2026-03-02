package com.ailtontech.todoistia

interface Platform {
    val name: String
}

expect fun getPlatform(): Platform