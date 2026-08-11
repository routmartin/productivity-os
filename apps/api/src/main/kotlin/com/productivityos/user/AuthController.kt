package com.productivityos.user

import jakarta.servlet.http.Cookie
import jakarta.servlet.http.HttpServletRequest
import jakarta.validation.Valid
import org.springframework.http.ResponseCookie
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import java.net.URI

@RestController
@RequestMapping("/api/v1/auth")
class AuthController(
    private val registrationService: RegistrationService,
    private val loginService: LoginService,
    private val refreshTokenService: RefreshTokenService
) {

    @PostMapping("/register")
    fun register(@Valid @RequestBody request: RegisterRequest): ResponseEntity<UserResponse> {
        val user = registrationService.register(request)
        val location = URI.create("/api/v1/users/${user.id}")
        return ResponseEntity.created(location).body(
            UserResponse(
                id = user.id!!,
                email = user.email,
                timezone = user.timezone
            )
        )
    }

    @PostMapping("/login")
    fun login(@Valid @RequestBody request: LoginRequest): ResponseEntity<LoginResponse> {
        val result = loginService.login(request)
        val refreshCookie = buildRefreshCookie(result.refreshToken)

        return ResponseEntity.ok()
            .header(org.springframework.http.HttpHeaders.SET_COOKIE, refreshCookie.toString())
            .body(
                LoginResponse(
                    accessToken = result.accessToken,
                    user = UserResponse(
                        id = result.user.id!!,
                        email = result.user.email,
                        timezone = result.user.timezone
                    )
                )
            )
    }

    @PostMapping("/refresh")
    fun refresh(request: HttpServletRequest): ResponseEntity<LoginResponse> {
        val refreshToken = extractRefreshToken(request)
            ?: return ResponseEntity.status(401).build()

        val pair = refreshTokenService.refresh(refreshToken)
        val refreshCookie = buildRefreshCookie(pair.refreshToken)

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
        val clearedCookie = ResponseCookie.from("refresh_token", "")
            .httpOnly(true)
            .secure(true)
            .sameSite("Strict")
            .path("/api/v1/auth")
            .maxAge(0)
            .build()
        return ResponseEntity.noContent()
            .header(org.springframework.http.HttpHeaders.SET_COOKIE, clearedCookie.toString())
            .build()
    }

    private fun buildRefreshCookie(token: String): ResponseCookie {
        return ResponseCookie.from("refresh_token", token)
            .httpOnly(true)
            .secure(true)
            .sameSite("Strict")
            .path("/api/v1/auth")
            .maxAge(30 * 86400)
            .build()
    }

    private fun extractRefreshToken(request: HttpServletRequest): String? {
        return request.cookies?.find { it.name == "refresh_token" }?.value
    }
}
