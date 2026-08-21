package com.productivityos

import com.tngtech.archunit.core.domain.JavaClasses
import com.tngtech.archunit.junit.AnalyzeClasses
import com.tngtech.archunit.junit.ArchTest
import com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes
import com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses

/**
 * Module-boundary rules for the modular monolith (ADR-002, ADR-007).
 *
 * Layout: every feature module (user, auth, task, project, goal, focus,
 * dailyplan, topthree) uses controller/, service/, domain/, persistence/,
 * dto/, exception/ sub-packages (auth also security/); api/ and config/ are
 * shared cross-cutting packages.
 *
 * Allowed cross-module edges:
 *   auth      -> user
 *   focus     -> task
 *   dailyplan -> task, user
 *   topthree  -> task, project, user
 *   project   -> goal (consumes goal lifecycle events)
 *   task <-> project  (known cycle, frozen; follow-up resolves it via events)
 */
@AnalyzeClasses(packages = ["com.productivityos"])
class ArchitectureTest {

    @ArchTest
    fun user_module_depends_only_on_shared_packages(classes: JavaClasses) {
        noClasses().that().resideInAPackage("com.productivityos.user..")
            .should().dependOnClassesThat().resideInAnyPackage(
                "com.productivityos.task..",
                "com.productivityos.project..",
                "com.productivityos.goal..",
                "com.productivityos.focus..",
                "com.productivityos.dailyplan..",
                "com.productivityos.topthree..",
                "com.productivityos.auth.."
            ).check(classes)
    }

    @ArchTest
    fun auth_module_depends_only_on_user_and_shared_packages(classes: JavaClasses) {
        noClasses().that().resideInAPackage("com.productivityos.auth..")
            .should().dependOnClassesThat().resideInAnyPackage(
                "com.productivityos.task..",
                "com.productivityos.project..",
                "com.productivityos.goal..",
                "com.productivityos.focus..",
                "com.productivityos.dailyplan..",
                "com.productivityos.topthree.."
            ).check(classes)
    }

    @ArchTest
    fun task_module_depends_only_on_project_auth_and_shared_packages(classes: JavaClasses) {
        noClasses().that().resideInAPackage("com.productivityos.task..")
            .should().dependOnClassesThat().resideInAnyPackage(
                "com.productivityos.user..",
                "com.productivityos.goal..",
                "com.productivityos.focus..",
                "com.productivityos.dailyplan..",
                "com.productivityos.topthree.."
            ).check(classes)
    }

    @ArchTest
    fun project_module_depends_only_on_task_goal_auth_and_shared_packages(classes: JavaClasses) {
        noClasses().that().resideInAPackage("com.productivityos.project..")
            .should().dependOnClassesThat().resideInAnyPackage(
                "com.productivityos.user..",
                "com.productivityos.focus..",
                "com.productivityos.dailyplan..",
                "com.productivityos.topthree.."
            ).check(classes)
    }

    @ArchTest
    fun goal_module_depends_only_on_auth_and_shared_packages(classes: JavaClasses) {
        noClasses().that().resideInAPackage("com.productivityos.goal..")
            .should().dependOnClassesThat().resideInAnyPackage(
                "com.productivityos.user..",
                "com.productivityos.task..",
                "com.productivityos.project..",
                "com.productivityos.focus..",
                "com.productivityos.dailyplan..",
                "com.productivityos.topthree.."
            ).check(classes)
    }

    @ArchTest
    fun focus_module_depends_only_on_task_auth_and_shared_packages(classes: JavaClasses) {
        noClasses().that().resideInAPackage("com.productivityos.focus..")
            .should().dependOnClassesThat().resideInAnyPackage(
                "com.productivityos.user..",
                "com.productivityos.project..",
                "com.productivityos.goal..",
                "com.productivityos.dailyplan..",
                "com.productivityos.topthree.."
            ).check(classes)
    }

    @ArchTest
    fun dailyplan_module_depends_only_on_task_user_auth_and_shared_packages(classes: JavaClasses) {
        noClasses().that().resideInAPackage("com.productivityos.dailyplan..")
            .should().dependOnClassesThat().resideInAnyPackage(
                "com.productivityos.project..",
                "com.productivityos.goal..",
                "com.productivityos.focus..",
                "com.productivityos.topthree.."
            ).check(classes)
    }

    @ArchTest
    fun topthree_module_depends_only_on_task_project_user_auth_and_shared_packages(classes: JavaClasses) {
        noClasses().that().resideInAPackage("com.productivityos.topthree..")
            .should().dependOnClassesThat().resideInAnyPackage(
                "com.productivityos.goal..",
                "com.productivityos.focus..",
                "com.productivityos.dailyplan.."
            ).check(classes)
    }

    @ArchTest
    fun controllers_depend_only_on_dto_api_and_config_outside_own_module(classes: JavaClasses) {
        classes().that().resideInAPackage("com.productivityos..controller..")
            .should().onlyDependOnClassesThat().resideInAnyPackage(
                "com.productivityos..controller..",
                "com.productivityos..dto..",
                "com.productivityos..service..",
                "com.productivityos..api..",
                "com.productivityos..config..",
                "java..",
                "kotlin..",
                "org.jetbrains..",
                "org.springframework..",
                "jakarta..",
                "io.swagger..",
                "com.fasterxml..",
                "org.slf4j.."
            ).check(classes)
    }

    @ArchTest
    fun domain_depends_only_on_domain_and_jdk(classes: JavaClasses) {
        classes().that().resideInAPackage("com.productivityos..domain..")
            .should().onlyDependOnClassesThat().resideInAnyPackage(
                "com.productivityos..domain..",
                "java..",
                "kotlin..",
                "org.jetbrains.."
            ).check(classes)
    }
}
