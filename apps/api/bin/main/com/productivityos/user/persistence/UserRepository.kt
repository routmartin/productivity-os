package com.productivityos.user.persistence

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.util.UUID

interface UserRepository : JpaRepository<UserEntity, UUID> {

    @Query("SELECT u FROM UserEntity u WHERE lower(u.email) = lower(:email)")
    fun findByEmailIgnoreCase(email: String): UserEntity?

    @Query("SELECT COUNT(u) > 0 FROM UserEntity u WHERE lower(u.email) = lower(:email)")
    fun existsByEmail(email: String): Boolean
}
