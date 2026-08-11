package com.productivityos

import com.tngtech.archunit.junit.AnalyzeClasses

/**
 * Module-boundary skeleton (Plan 001, Step 1; ADR-002 modular monolith).
 * Rules are intentionally minimal while the codebase is small; they grow
 * as the user/task/planning modules are introduced.
 *
 * Known: project↔task package cycle from cross-module validation
 * (ProjectService uses TaskRepository to count unresolved tasks,
 *  TaskService uses ProjectRepository to validate project ownership).
 * Accepted for now; refactor with events if needed later.
 */
@AnalyzeClasses(packages = ["com.productivityos"])
class ArchitectureTest {
}
