package com.productivityos.user

import com.fasterxml.jackson.databind.ObjectMapper
import com.productivityos.api.ErrorResponse
import com.productivityos.api.TraceIdFilter
import jakarta.servlet.http.HttpServletResponse
import org.slf4j.MDC
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.http.MediaType
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.web.SecurityFilterChain
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter

@Configuration
@EnableWebSecurity
class SecurityConfig(
    private val jwtAuthenticationFilter: JwtAuthenticationFilter,
    private val objectMapper: ObjectMapper
) {

    @Bean
    fun filterChain(http: HttpSecurity): SecurityFilterChain {
        http
            .csrf { it.disable() }
            .sessionManagement { it.sessionCreationPolicy(SessionCreationPolicy.STATELESS) }
            .exceptionHandling { handling ->
                // Expired/missing/invalid tokens must surface as 401 (not
                // Spring's default 403) so the web client can silent-refresh
                // (spec AC-006/AC-007 — the client refreshes on 401 only).
                handling.authenticationEntryPoint { _, response, _ ->
                    response.status = HttpServletResponse.SC_UNAUTHORIZED
                    response.contentType = MediaType.APPLICATION_JSON_VALUE
                    response.setHeader("WWW-Authenticate", "Bearer")
                    objectMapper.writeValue(
                        response.writer,
                        ErrorResponse(
                            code = "UNAUTHORIZED",
                            message = "Authentication required",
                            traceId = MDC.get(TraceIdFilter.TRACE_ID_KEY) ?: "unknown"
                        )
                    )
                }
            }
            .authorizeHttpRequests { auth ->
                auth.requestMatchers(
                    "/api/v1/auth/**",
                    "/api/v1/health",
                    "/docs",
                    "/swagger-ui/**",
                    "/swagger-ui.html",
                    "/v3/api-docs/**"
                ).permitAll()
                auth.anyRequest().authenticated()
            }
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter::class.java)

        return http.build()
    }
}
