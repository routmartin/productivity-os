package com.productivityos.auth

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule
import com.productivityos.api.CurrentUser
import com.productivityos.api.GlobalExceptionHandler
import com.productivityos.auth.controller.AuthController
import com.productivityos.auth.dto.LoginRequest
import com.productivityos.auth.dto.QrExchangeRequest
import com.productivityos.auth.service.LoginService
import com.productivityos.auth.service.QrAuthService
import com.productivityos.auth.service.RefreshTokenService
import com.productivityos.auth.service.RegistrationService
import com.productivityos.user.domain.User
import jakarta.servlet.http.Cookie
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.Mockito.`when`
import org.mockito.Mockito.mock
import org.mockito.Mockito.verify
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.header
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import org.springframework.test.web.servlet.setup.MockMvcBuilders
import java.time.Instant
import java.util.UUID

class AuthControllerTest {

    private lateinit var mockMvc: MockMvc
    private lateinit var registrationService: RegistrationService
    private lateinit var loginService: LoginService
    private lateinit var refreshTokenService: RefreshTokenService
    private lateinit var qrAuthService: QrAuthService
    private lateinit var currentUser: CurrentUser
    private val objectMapper = ObjectMapper().registerModule(JavaTimeModule())

    private val userId = UUID.randomUUID()

    @BeforeEach
    fun setUp() {
        registrationService = mock(RegistrationService::class.java)
        loginService = mock(LoginService::class.java)
        refreshTokenService = mock(RefreshTokenService::class.java)
        qrAuthService = mock(QrAuthService::class.java)
        currentUser = mock(CurrentUser::class.java)

        `when`(currentUser.id()).thenReturn(userId)

        val controller = AuthController(
            registrationService = registrationService,
            loginService = loginService,
            refreshTokenService = refreshTokenService,
            qrAuthService = qrAuthService,
            currentUser = currentUser,
            cookieSameSite = "Strict",
            cookieSecure = false
        )

        mockMvc = MockMvcBuilders.standaloneSetup(controller)
            .setControllerAdvice(GlobalExceptionHandler())
            .build()
    }

    @Test
    fun `login returns 200 with LoginResponse containing refreshToken and Set-Cookie header`() {
        val request = LoginRequest(email = "user@example.com", password = "password123")
        val user = User(
            id = userId,
            email = "user@example.com",
            timezone = "UTC",
            createdAt = Instant.now()
        )
        `when`(loginService.login(request)).thenReturn(
            LoginService.LoginResult(
                accessToken = "jwt-access-token",
                refreshToken = "raw-refresh-token",
                user = user
            )
        )

        mockMvc.perform(
            post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)
            .andExpect(header().exists("Set-Cookie"))
            .andExpect(jsonPath("$.accessToken").value("jwt-access-token"))
            .andExpect(jsonPath("$.refreshToken").value("raw-refresh-token"))
            .andExpect(jsonPath("$.user.email").value("user@example.com"))
    }

    @Test
    fun `refresh with cookie returns 200 with new accessToken and refreshToken`() {
        `when`(refreshTokenService.refresh("cookie-refresh-token")).thenReturn(
            RefreshTokenService.TokenPair(
                accessToken = "new-access-token",
                refreshToken = "new-refresh-token"
            )
        )

        mockMvc.perform(
            post("/api/v1/auth/refresh")
                .cookie(Cookie("refresh_token", "cookie-refresh-token"))
        )
            .andExpect(status().isOk)
            .andExpect(header().exists("Set-Cookie"))
            .andExpect(jsonPath("$.accessToken").value("new-access-token"))
            .andExpect(jsonPath("$.refreshToken").value("new-refresh-token"))

        verify(refreshTokenService).refresh("cookie-refresh-token")
    }

    @Test
    fun `refresh with X-Refresh-Token header succeeds when cookie is absent`() {
        `when`(refreshTokenService.refresh("header-refresh-token")).thenReturn(
            RefreshTokenService.TokenPair(
                accessToken = "new-access-token-header",
                refreshToken = "new-refresh-token-header"
            )
        )

        mockMvc.perform(
            post("/api/v1/auth/refresh")
                .header("X-Refresh-Token", "header-refresh-token")
        )
            .andExpect(status().isOk)
            .andExpect(header().exists("Set-Cookie"))
            .andExpect(jsonPath("$.accessToken").value("new-access-token-header"))
            .andExpect(jsonPath("$.refreshToken").value("new-refresh-token-header"))

        verify(refreshTokenService).refresh("header-refresh-token")
    }

    @Test
    fun `refresh prefers cookie over X-Refresh-Token header`() {
        `when`(refreshTokenService.refresh("preferred-cookie-token")).thenReturn(
            RefreshTokenService.TokenPair(
                accessToken = "token-from-cookie",
                refreshToken = "new-cookie-token"
            )
        )

        mockMvc.perform(
            post("/api/v1/auth/refresh")
                .cookie(Cookie("refresh_token", "preferred-cookie-token"))
                .header("X-Refresh-Token", "ignored-header-token")
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.accessToken").value("token-from-cookie"))
            .andExpect(jsonPath("$.refreshToken").value("new-cookie-token"))

        verify(refreshTokenService).refresh("preferred-cookie-token")
    }

    @Test
    fun `refresh returns 401 when both cookie and header are missing`() {
        mockMvc.perform(post("/api/v1/auth/refresh"))
            .andExpect(status().isUnauthorized)
    }

    @Test
    fun `refresh with grace cache miss returns 200 without Set-Cookie and null refreshToken in body`() {
        `when`(refreshTokenService.refresh("grace-token")).thenReturn(
            RefreshTokenService.TokenPair(
                accessToken = "new-access-token-grace",
                refreshToken = null
            )
        )

        mockMvc.perform(
            post("/api/v1/auth/refresh")
                .header("X-Refresh-Token", "grace-token")
        )
            .andExpect(status().isOk)
            .andExpect(header().doesNotExist("Set-Cookie"))
            .andExpect(jsonPath("$.accessToken").value("new-access-token-grace"))
            .andExpect(jsonPath("$.refreshToken").doesNotExist())
    }

    @Test
    fun `logout extracts token from X-Refresh-Token header and calls logout`() {
        mockMvc.perform(
            post("/api/v1/auth/logout")
                .header("X-Refresh-Token", "header-logout-token")
        )
            .andExpect(status().isNoContent)
            .andExpect(header().exists("Set-Cookie"))

        verify(refreshTokenService).logout("header-logout-token")
    }

    @Test
    fun `logout extracts token from cookie when present`() {
        mockMvc.perform(
            post("/api/v1/auth/logout")
                .cookie(Cookie("refresh_token", "cookie-logout-token"))
                .header("X-Refresh-Token", "ignored-header-logout")
        )
            .andExpect(status().isNoContent)
            .andExpect(header().exists("Set-Cookie"))

        verify(refreshTokenService).logout("cookie-logout-token")
    }

    @Test
    fun `qr exchange returns 200 with LoginResponse containing refreshToken`() {
        val request = QrExchangeRequest(challenge = "challenge-123")
        val user = User(
            id = userId,
            email = "user@example.com",
            timezone = "UTC",
            createdAt = Instant.now()
        )
        `when`(qrAuthService.exchange("challenge-123")).thenReturn(
            LoginService.LoginResult(
                accessToken = "qr-jwt-access-token",
                refreshToken = "qr-refresh-token",
                user = user
            )
        )

        mockMvc.perform(
            post("/api/v1/auth/qr/exchange")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)
            .andExpect(header().exists("Set-Cookie"))
            .andExpect(jsonPath("$.accessToken").value("qr-jwt-access-token"))
            .andExpect(jsonPath("$.refreshToken").value("qr-refresh-token"))
            .andExpect(jsonPath("$.user.email").value("user@example.com"))
    }
}
