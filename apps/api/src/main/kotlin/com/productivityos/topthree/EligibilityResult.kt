package com.productivityos.topthree

data class EligibilityResult(
    val eligible: Boolean,
    val reason: String?
) {
    companion object {
        fun eligible(): EligibilityResult = EligibilityResult(true, null)
        fun ineligible(reason: String): EligibilityResult = EligibilityResult(false, reason)
    }
}
