package com.productivityos.user

import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@Tag(name = "Users", description = "Password change, timezone change")
@RequestMapping("/api/v1/users")
class UserController(
    private val userService: UserService,
    private val currentUser: CurrentUser
) {
    @PutMapping("/password")
    fun changePassword(@Valid @RequestBody request: ChangePasswordRequest): ResponseEntity<UserResponse> {
        val result = userService.changePassword(currentUser.id(), request)
        return ResponseEntity.ok(result)
    }

    @PutMapping("/timezone")
    fun changeTimezone(@Valid @RequestBody request: ChangeTimezoneRequest): ResponseEntity<UserResponse> {
        val result = userService.changeTimezone(currentUser.id(), request)
        return ResponseEntity.ok(result)
    }
}
