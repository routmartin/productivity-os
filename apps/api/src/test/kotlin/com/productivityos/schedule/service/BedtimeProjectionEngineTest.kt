package com.productivityos.schedule.service

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class BedtimeProjectionEngineTest {

    private val engine = BedtimeProjectionEngine()

    @Test
    fun `overflow is zero when there are no pending habits or incomplete activities`() {
        val overflow = engine.calculateOverflow(0, 0)
        assertEquals(0, overflow)
    }

    @Test
    fun `overflow scales by 15 minutes per pending item`() {
        assertEquals(15, engine.calculateOverflow(1, 0))
        assertEquals(15, engine.calculateOverflow(0, 1))
        assertEquals(30, engine.calculateOverflow(1, 1))
        assertEquals(45, engine.calculateOverflow(2, 1))
    }

    @Test
    fun `overflow is capped at 45 minutes maximum`() {
        assertEquals(45, engine.calculateOverflow(5, 5))
        assertEquals(45, engine.calculateOverflow(10, 0))
        assertEquals(45, engine.calculateOverflow(3, 1))
    }

    @Test
    fun `calculateProjectedTime formats time correctly with overflow`() {
        assertEquals("22:30", engine.calculateProjectedTime("22:30", 0))
        assertEquals("22:45", engine.calculateProjectedTime("22:30", 15))
        assertEquals("23:00", engine.calculateProjectedTime("22:30", 30))
        assertEquals("23:15", engine.calculateProjectedTime("22:30", 45))
    }

    @Test
    fun `calculateProjectedTime handles midnight rollover`() {
        assertEquals("00:15", engine.calculateProjectedTime("23:45", 30))
    }
}
