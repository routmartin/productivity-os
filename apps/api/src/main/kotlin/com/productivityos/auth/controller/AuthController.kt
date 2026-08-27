package com.productivityos.auth.controller

import jakarta.servlet.http.Cookie
import jakarta.servlet.http.HttpServletRequest
import jakarta.validation.Valid
import org.springframework.http.ResponseCookie
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.beans.factory.annotation.Value
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.net.URI
import com.productivityos.auth.dto.LoginRequest
import com.productivityos.auth.dto.LoginResponse
import com.productivityos.auth.dto.RegisterRequest
import com.productivityos.auth.dto.QrChallengeResponse
import com.productivityos.auth.dto.QrExchangeRequest
import com.productivityos.auth.service.LoginService
import com.productivityos.auth.service.RefreshTokenService
import com.productivityos.auth.service.RegistrationService
import com.productivityos.auth.service.QrAuthService
import com.productivityos.api.CurrentUser
import com.productivityos.user.dto.UserResponse

@RestController
@Tag(name = "Auth", description = "Register, login, refresh, logout, QR authentication")
@RequestMapping("/api/v1/auth")
class AuthController(
    private val registrationService: RegistrationService,
    private val loginService: LoginService,
    private val refreshTokenService: RefreshTokenService,
    private val qrAuthService: QrAuthService,
    private val currentUser: CurrentUser,
    @Value("\${app.auth.cookie-same-site}") private val cookieSameSite: String,
    @Value("\${app.auth.cookie-secure:false}") private val cookieSecure: Boolean
) {

    @PostMapping("/register")
    fun register(@Valid @RequestBody request: RegisterRequest): ResponseEntity<UserResponse> {
        val user = registrationService.register(request)
        val response = UserResponse.from(user)
        val location = URI.create("/api/v1/users/${response.id}")
        return ResponseEntity.created(location).body(response)
    }

    @PostMapping("/login")
    fun login(
        @Valid @RequestBody request: LoginRequest,
        httpRequest: HttpServletRequest
    ): ResponseEntity<LoginResponse> {
        val result = loginService.login(request)
        val refreshCookie = buildRefreshCookie(result.refreshToken, httpRequest.isSecure)

        return ResponseEntity.ok()
            .header(org.springframework.http.HttpHeaders.SET_COOKIE, refreshCookie.toString())
            .body(
                LoginResponse(
                    accessToken = result.accessToken,
                    user = UserResponse.from(result.user)
                )
            )
    }

    @PostMapping("/refresh")
    fun refresh(request: HttpServletRequest): ResponseEntity<LoginResponse> {
        val refreshToken = extractRefreshToken(request)
            ?: return ResponseEntity.status(401).build()

        val pair = refreshTokenService.refresh(refreshToken)
        val refreshCookie = buildRefreshCookie(pair.refreshToken, request.isSecure)

        return ResponseEntity.ok()
            .header(org.springframework.http.HttpHeaders.SET_COOKIE, refreshCookie.toString())
            .body(LoginResponse(accessToken = pair.accessToken, user = null))
    }

    @PostMapping("/logout")
    fun logout(request: HttpServletRequest): ResponseEntity<Void> {
        val refreshToken = extractRefreshToken(request)
        if (refreshToken != null) {
            refreshTokenService.logout(refreshToken)
        }
        val secureFlag = cookieSecure || cookieSameSite.equals("None", ignoreCase = true) || request.isSecure
        val clearedCookie = ResponseCookie.from("refresh_token", "")
            .httpOnly(true)
            .secure(secureFlag)
            .sameSite(cookieSameSite)
            .path("/api/v1/auth")
            .maxAge(0)
            .build()
        return ResponseEntity.noContent()
            .header(org.springframework.http.HttpHeaders.SET_COOKIE, clearedCookie.toString())
            .build()
    }

    @PostMapping("/qr/challenge")
    fun createQrChallenge(): ResponseEntity<QrChallengeResponse> {
        val challenge = qrAuthService.createChallenge(currentUser.id())
        return ResponseEntity.ok(
            QrChallengeResponse(
                challenge = challenge.challenge,
                expiresAt = challenge.expiresAt
            )
        )
    }

    @PostMapping("/qr/exchange")
    fun exchangeQrChallenge(
        @Valid @RequestBody request: QrExchangeRequest,
        httpRequest: HttpServletRequest
    ): ResponseEntity<LoginResponse> {
        val result = qrAuthService.exchange(request.challenge)
        val refreshCookie = buildRefreshCookie(result.refreshToken, httpRequest.isSecure)

        return ResponseEntity.ok()
            .header(org.springframework.http.HttpHeaders.SET_COOKIE, refreshCookie.toString())
            .body(
                LoginResponse(
                    accessToken = result.accessToken,
                    user = UserResponse.from(result.user)
                )
            )
    }

    private fun buildRefreshCookie(token: String, isHttps: Boolean = false): ResponseCookie {
        val secureFlag = cookieSecure || cookieSameSite.equals("None", ignoreCase = true) || isHttps
        return ResponseCookie.from("refresh_token", token)
            .httpOnly(true)
            .secure(secureFlag)
            .sameSite(cookieSameSite)
            .path("/api/v1/auth")
            .maxAge(30 * 86400)
            .build()
    }

    private fun extractRefreshToken(request: HttpServletRequest): String? {
        return request.cookies?.find { it.name == "refresh_token" }?.value
    }
}
