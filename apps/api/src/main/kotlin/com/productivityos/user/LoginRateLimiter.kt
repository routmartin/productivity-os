package com.productivityos.user

import org.springframework.stereotype.Component
import java.time.Clock
import java.time.Instant
import java.util.concurrent.ConcurrentHashMap

@Component
class LoginRateLimiter(
    private val clock: Clock
) {
    private val attempts = ConcurrentHashMap<String, MutableList<Instant>>()

    companion object {
        private const val MAX_ATTEMPTS = 5
        private const val WINDOW_MINUTES = 15L
        private const val LOCKOUT_MINUTES = 15L
    }

    fun recordFailure(email: String) {
        val now = clock.instant()
        val windowStart = now.minusSeconds(WINDOW_MINUTES * 60)

        val emailKey = email.lowercase()
        val recent = attempts.getOrPut(emailKey) { mutableListOf() }
        recent.removeIf { it.isBefore(windowStart) }
        recent.add(now)
    }

    fun isLocked(email: String): Boolean {
        val recent = attempts[email.lowercase()] ?: return false
        val now = clock.instant()
        val windowStart = now.minusSeconds(WINDOW_MINUTES * 60)
        val lockoutStart = now.minusSeconds(LOCKOUT_MINUTES * 60)

        recent.removeIf { it.isBefore(windowStart) }

        if (recent.size >= MAX_ATTEMPTS) {
            val oldestFailure = recent.first()
            if (oldestFailure.isAfter(lockoutStart)) return true
            recent.clear()
        }
        return false
    }

    fun clear(email: String) {
        attempts.remove(email.lowercase())
    }
}
