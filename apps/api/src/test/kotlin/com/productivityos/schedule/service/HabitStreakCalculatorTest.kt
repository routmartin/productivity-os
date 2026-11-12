package com.productivityos.schedule.service

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import java.time.LocalDate

class HabitStreakCalculatorTest {

    private val calculator = HabitStreakCalculator()
    private val today = LocalDate.of(2026, 11, 11)

    @Test
    fun `streak is 0 when there are no occurrences`() {
        val streak = calculator.calculateStreak(emptySet(), today)
        assertEquals(0, streak)
    }

    @Test
    fun `streak is 1 when only today is completed`() {
        val streak = calculator.calculateStreak(setOf(today), today)
        assertEquals(1, streak)
    }

    @Test
    fun `streak reflects yesterday when today is not completed yet`() {
        val occurrences = setOf(today.minusDays(1), today.minusDays(2))
        val streak = calculator.calculateStreak(occurrences, today)
        assertEquals(2, streak)
    }

    @Test
    fun `streak increments when today is also completed`() {
        val occurrences = setOf(today, today.minusDays(1), today.minusDays(2))
        val streak = calculator.calculateStreak(occurrences, today)
        assertEquals(3, streak)
    }

    @Test
    fun `streak resets on missed day in the past`() {
        // missed yesterday (day - 1), but completed day - 2 and day - 3
        val occurrences = setOf(today, today.minusDays(2), today.minusDays(3))
        val streak = calculator.calculateStreak(occurrences, today)
        assertEquals(1, streak)
    }

    @Test
    fun `generate14DayHistory produces exactly 14 items ending on anchorDate`() {
        val occurrences = setOf(today, today.minusDays(1), today.minusDays(5))
        val history = calculator.generate14DayHistory(occurrences, today)

        assertEquals(14, history.size)
        assertEquals(today.minusDays(13).toString(), history.first().date)
        assertEquals(today.toString(), history.last().date)

        assertTrue(history.last().completed)
        assertTrue(history[12].completed) // today - 1
        assertTrue(history[8].completed)  // today - 5
        assertFalse(history[0].completed) // today - 13
    }
}
