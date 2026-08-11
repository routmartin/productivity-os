package com.productivityos

import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.runApplication

@SpringBootApplication
class ProductivityOsApplication

fun main(args: Array<String>) {
    runApplication<ProductivityOsApplication>(*args)
}
