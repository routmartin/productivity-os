package com.productivityos.user.persistence

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.Version
import java.time.Instant
import java.util.UUID
import com.productivityos.user.domain.User

@Entity
@Table(name = "users")
class UserEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    val id: UUID? = null,

    @Column(nullable = false)
    val email: String,

    @Column(name = "password_hash", nullable = false)
    var passwordHash: String,

    @Column(nullable = false)
    var timezone: String = "UTC",

    @Column(name = "created_at", nullable = false, updatable = false)
    val createdAt: Instant,

    @Version
    var version: Long = 0
) {

    fun toDomain(): User = User(
        id = id!!,
        email = email,
        timezone = timezone,
        createdAt = createdAt
    )
}
