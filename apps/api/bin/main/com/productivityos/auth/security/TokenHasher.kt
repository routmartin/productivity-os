package com.productivityos.auth.security

import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.util.Base64

object TokenHasher {
    fun hash(token: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val hash = digest.digest(token.toByteArray(StandardCharsets.UTF_8))
        return Base64.getEncoder().encodeToString(hash)
    }
}
