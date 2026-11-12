package com.productivityos.schedule.service

import com.productivityos.schedule.dto.HabitStreakDayDTO
import org.springframework.stereotype.Component
import java.time.LocalDate

@Component
class HabitStreakCalculator {

    fun calculateStreak(occurrences: Set<LocalDate>, anchorDate: LocalDate): Int {
        var streak = 0
        var checkDate = if (occurrences.contains(anchorDate)) {
            streak++
            anchorDate.minusDays(1)
        } else {
            anchorDate.minusDays(1)
        }

        while (occurrences.contains(checkDate)) {
            streak++
            checkDate = checkDate.minusDays(1)
        }

        return streak
    }

    fun generate14DayHistory(occurrences: Set<LocalDate>, anchorDate: LocalDate): List<HabitStreakDayDTO> {
        val days = ArrayList<HabitStreakDayDTO>(14)
        for (i in 13 downTo 0) {
            val date = anchorDate.minusDays(i.toLong())
            days.add(HabitStreakDayDTO(date = date.toString(), completed = occurrences.contains(date)))
        }
        return days
    }
}
