package com.productivityos.auth.persistence

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.util.*

@Repository
interface QrAuthChallengeRepository : JpaRepository<QrAuthChallengeEntity, UUID> {
    fun findByChallenge(challenge: String): QrAuthChallengeEntity?
}
