package com.productivityos.user

data class LoginResponse(
    val accessToken: String,
    val user: UserResponse? = null
)
