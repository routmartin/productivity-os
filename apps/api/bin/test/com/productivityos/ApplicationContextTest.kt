package com.productivityos

import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.testcontainers.service.connection.ServiceConnection
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers

/**
 * Plan 001, Steps 1-2: the application context starts and Flyway
 * migrations apply against a real PostgreSQL (Testcontainers, ADR-003).
 */
@Testcontainers
@SpringBootTest
@AutoConfigureMockMvc
class ApplicationContextTest {

    companion object {
        @Container
        @ServiceConnection
        @JvmStatic
        val postgres = PostgreSQLContainer("postgres:16-alpine")
    }

    @Autowired
    lateinit var mockMvc: MockMvc

    @Test
    fun `context loads and migrations apply`() {
        // Startup succeeding means Flyway applied V1__baseline.sql cleanly.
    }

    @Test
    fun `health endpoint returns ok`() {
        mockMvc.get("/api/v1/health")
            .andExpect { status { isOk() } }
            .andExpect { jsonPath("$.status") { value("ok") } }
    }
}
