package com.productivityos.auth.persistence

import jakarta.persistence.*
import java.time.Instant
import java.util.*

@Entity
@Table(name = "qr_auth_challenges")
class QrAuthChallengeEntity(
    @Id
    val id: UUID = UUID.randomUUID(),

    @Column(nullable = false, unique = true)
    val challenge: String,

    @Column(name = "user_id", nullable = false)
    val userId: UUID,

    @Column(name = "expires_at", nullable = false)
    val expiresAt: Instant,

    @Column(name = "used_at")
    var usedAt: Instant? = null,

    @Column(name = "created_at", nullable = false)
    val createdAt: Instant = Instant.now()
)
