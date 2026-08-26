package com.productivityos.auth.dto

import com.productivityos.user.dto.UserResponse

data class LoginResponse(
    val accessToken: String,
    val user: UserResponse? = null
)
