package com.productivityos

import com.tngtech.archunit.junit.AnalyzeClasses
import com.tngtech.archunit.junit.ArchTest
import com.tngtech.archunit.lang.ArchRule
import com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices

/**
 * Module-boundary skeleton (Plan 001, Step 1; ADR-002 modular monolith).
 * Rules are intentionally minimal while the codebase is small; they grow
 * as the user/task/planning modules are introduced.
 */
@AnalyzeClasses(packages = ["com.productivityos"])
class ArchitectureTest {

    @ArchTest
    val `module packages are free of cycles`: ArchRule = slices()
        .matching("com.productivityos.(*)..")
        .should()
        .beFreeOfCycles()
}
