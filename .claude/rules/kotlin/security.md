> This file extends [common/security.md](../common/security.md) with Kotlin-specific content.

# Kotlin Security

## No `!!` in Production Code

The `!!` operator bypasses null safety and causes unhandled `NullPointerException` crashes — treat it like a security and stability risk.

```kotlin
// WRONG — crash risk
val token = prefs.getString("token")!!

// CORRECT
val token = prefs.getString("token") ?: error("Auth token missing")
```

## Wrap Sensitive Values in Value Classes

Plain `String` for tokens, passwords, or secrets is easy to log accidentally. Wrap them in a `value class` to make misuse visible at compile time.

```kotlin
@JvmInline
value class AuthToken(val value: String) {
    override fun toString() = "AuthToken(***)"
}
```

## Never Log Sensitive Data

Do not log tokens, passwords, user identifiers, or personal data. In coroutines, exceptions can surface in unexpected log sinks.

```kotlin
// WRONG
Log.d("Auth", "Token: $token")

// CORRECT
Log.d("Auth", "Token present: ${token != null}")
```

## Secrets in Environment / BuildConfig Only

Never hardcode API keys, base URLs with credentials, or secrets in source files. Use environment variables injected at build time via `local.properties` and `BuildConfig`.

```kotlin
// WRONG
const val API_KEY = "sk-abc123"

// CORRECT — injected at build time
val apiKey = BuildConfig.API_KEY
```

## Kotlin Security Checklist

- [ ] No `!!` operator in production code
- [ ] Sensitive values wrapped in `value class` with redacted `toString()`
- [ ] No sensitive data in log statements
- [ ] No hardcoded secrets — all secrets via `BuildConfig` or environment
- [ ] `runCatching` used around network/IO calls to avoid unhandled exceptions leaking stack traces
