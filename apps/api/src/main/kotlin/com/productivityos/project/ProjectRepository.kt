package com.productivityos.project

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.util.UUID

interface ProjectRepository : JpaRepository<ProjectEntity, UUID> {

    @Query("SELECT p FROM ProjectEntity p WHERE p.userId = :userId ORDER BY p.createdAt DESC")
    fun findAllByUserId(userId: UUID): List<ProjectEntity>
}
