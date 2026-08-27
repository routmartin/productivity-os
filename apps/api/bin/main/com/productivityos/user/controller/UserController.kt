package com.productivityos.user.controller

import jakarta.validation.Valid
import org.springframework.http.ResponseEntity
import io.swagger.v3.oas.annotations.tags.Tag
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import com.productivityos.api.CurrentUser
import com.productivityos.user.dto.ChangeTimezoneRequest
import com.productivityos.user.dto.UserResponse
import com.productivityos.user.service.UserService

@RestController
@Tag(name = "Users", description = "Timezone change")
@RequestMapping("/api/v1/users")
class UserController(
    private val userService: UserService,
    private val currentUser: CurrentUser
) {
    @PutMapping("/timezone")
    fun changeTimezone(@Valid @RequestBody request: ChangeTimezoneRequest): ResponseEntity<UserResponse> {
        val result = userService.changeTimezone(currentUser.id(), request)
        return ResponseEntity.ok(result)
    }
}
