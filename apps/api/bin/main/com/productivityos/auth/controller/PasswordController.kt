package com.productivityos.auth.controller

import com.productivityos.api.CurrentUser
import com.productivityos.auth.dto.ChangePasswordRequest
import com.productivityos.auth.service.PasswordService
import com.productivityos.user.dto.UserResponse
import io.swagger.v3.oas.annotations.tags.Tag
import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@Tag(name = "Users", description = "Password change")
@RequestMapping("/api/v1/users")
class PasswordController(
    private val passwordService: PasswordService,
    private val currentUser: CurrentUser
) {

    @PutMapping("/password")
    fun changePassword(@Valid @RequestBody request: ChangePasswordRequest): ResponseEntity<UserResponse> {
        val result = passwordService.changePassword(currentUser.id(), request)
        return ResponseEntity.ok(result)
    }
}
