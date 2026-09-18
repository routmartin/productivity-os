package com.productivityos.focus.persistence

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.util.UUID

interface FocusSessionPauseRepository : JpaRepository<FocusSessionPauseEntity, UUID> {

    /** The session's currently open pause, if any (at most one by constraint). */
    @Query("SELECT p FROM FocusSessionPauseEntity p WHERE p.sessionId = :sessionId AND p.endedAt IS NULL")
    fun findOpenBySessionId(sessionId: UUID): FocusSessionPauseEntity?

    /** All closed pause intervals for a session, used to sum paused time. */
    @Query("SELECT p FROM FocusSessionPauseEntity p WHERE p.sessionId = :sessionId AND p.endedAt IS NOT NULL")
    fun findAllClosedBySessionId(sessionId: UUID): List<FocusSessionPauseEntity>
}
