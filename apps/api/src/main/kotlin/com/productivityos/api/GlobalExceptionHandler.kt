package com.productivityos.api

import com.productivityos.task.TaskNotFoundException
import com.productivityos.user.AuthenticationException
import com.productivityos.user.DuplicateEmailException
import com.productivityos.user.InvalidRefreshTokenException
import org.slf4j.MDC
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.MethodArgumentNotValidException
import org.springframework.web.bind.annotation.ControllerAdvice
import org.springframework.web.bind.annotation.ExceptionHandler
import java.time.DateTimeException

@ControllerAdvice
class GlobalExceptionHandler {

    @ExceptionHandler(TaskNotFoundException::class)
    fun handleTaskNotFound(ex: TaskNotFoundException): ResponseEntity<ErrorResponse> {
        val body = ErrorResponse(
            code = "NOT_FOUND",
            message = ex.message ?: "Not found",
            traceId = traceId()
        )
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(body)
    }

    @ExceptionHandler(IllegalArgumentException::class)
    fun handleIllegalArgument(ex: IllegalArgumentException): ResponseEntity<ErrorResponse> {
        val body = ErrorResponse(
            code = "CONFLICT",
            message = ex.message ?: "Invalid operation",
            traceId = traceId()
        )
        return ResponseEntity.status(HttpStatus.CONFLICT).body(body)
    }

    @ExceptionHandler(InvalidRefreshTokenException::class)
    fun handleInvalidRefreshToken(ex: InvalidRefreshTokenException): ResponseEntity<ErrorResponse> {
        val body = ErrorResponse(
            code = "invalid_token",
            message = "Refresh token is invalid or expired",
            traceId = traceId()
        )
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(body)
    }

    @ExceptionHandler(AuthenticationException::class)
    fun handleAuthenticationException(ex: AuthenticationException): ResponseEntity<ErrorResponse> {
        val body = ErrorResponse(
            code = "invalid_credentials",
            message = ex.message ?: "Invalid email or password",
            traceId = traceId()
        )
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(body)
    }

    @ExceptionHandler(DuplicateEmailException::class)
    fun handleDuplicateEmail(ex: DuplicateEmailException): ResponseEntity<ErrorResponse> {
        val body = ErrorResponse(
            code = "EMAIL_TAKEN",
            message = ex.message ?: "An account with this email already exists",
            traceId = traceId()
        )
        return ResponseEntity.status(HttpStatus.CONFLICT).body(body)
    }

    @ExceptionHandler(DateTimeException::class)
    fun handleDateTimeException(ex: DateTimeException): ResponseEntity<ErrorResponse> {
        val body = ErrorResponse(
            code = "INVALID_TIMEZONE",
            message = "Invalid timezone identifier",
            traceId = traceId()
        )
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body)
    }

    @ExceptionHandler(MethodArgumentNotValidException::class)
    fun handleValidationException(ex: MethodArgumentNotValidException): ResponseEntity<ErrorResponse> {
        val details = ex.bindingResult.fieldErrors.map {
            mapOf("field" to it.field, "message" to (it.defaultMessage ?: "Invalid value"))
        }
        val body = ErrorResponse(
            code = "VALIDATION_ERROR",
            message = "Request validation failed",
            details = details,
            traceId = traceId()
        )
        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(body)
    }

    @ExceptionHandler(DataIntegrityViolationException::class)
    fun handleDataIntegrityViolation(ex: DataIntegrityViolationException): ResponseEntity<ErrorResponse> {
        val body = ErrorResponse(
            code = "EMAIL_TAKEN",
            message = "An account with this email already exists",
            traceId = traceId()
        )
        return ResponseEntity.status(HttpStatus.CONFLICT).body(body)
    }

    @ExceptionHandler(Exception::class)
    fun handleUnexpected(ex: Exception): ResponseEntity<ErrorResponse> {
        val body = ErrorResponse(
            code = "INTERNAL_ERROR",
            message = "An unexpected error occurred",
            traceId = traceId()
        )
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(body)
    }

    private fun traceId(): String = MDC.get(TraceIdFilter.TRACE_ID_KEY) ?: "unknown"
}
