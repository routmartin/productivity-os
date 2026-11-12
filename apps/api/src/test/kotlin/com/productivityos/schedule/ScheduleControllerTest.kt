package com.productivityos.schedule

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule
import com.productivityos.api.CurrentUser
import com.productivityos.api.GlobalExceptionHandler
import com.productivityos.schedule.controller.ScheduleController
import com.productivityos.schedule.dto.AddScheduleStepRequest
import com.productivityos.schedule.dto.ScheduleGraphResponse
import com.productivityos.schedule.dto.ScheduleNodeDTO
import com.productivityos.schedule.dto.ToggleHabitRequest
import com.productivityos.schedule.dto.ToggleHabitResponse
import com.productivityos.schedule.exception.AnchorDeletionNotAllowedException
import com.productivityos.schedule.exception.ScheduleNodeNotFoundException
import com.productivityos.schedule.service.ScheduleService
import com.productivityos.user.service.UserTimezoneService
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.Mockito.`when`
import org.mockito.Mockito.doNothing
import org.mockito.Mockito.doThrow
import org.mockito.Mockito.mock
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.header
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import org.springframework.test.web.servlet.setup.MockMvcBuilders
import java.time.LocalDate
import java.util.UUID

class ScheduleControllerTest {

    private lateinit var mockMvc: MockMvc
    private lateinit var scheduleService: ScheduleService
    private lateinit var currentUser: CurrentUser
    private lateinit var userTimezoneService: UserTimezoneService
    private val objectMapper = ObjectMapper().registerModule(JavaTimeModule())

    private val userId = UUID.randomUUID()
    private val date = LocalDate.of(2026, 11, 11)

    @BeforeEach
    fun setUp() {
        scheduleService = mock(ScheduleService::class.java)
        currentUser = mock(CurrentUser::class.java)
        userTimezoneService = mock(UserTimezoneService::class.java)

        `when`(currentUser.id()).thenReturn(userId)
        `when`(userTimezoneService.today(userId)).thenReturn(date)

        val controller = ScheduleController(
            scheduleService = scheduleService,
            currentUser = currentUser,
            userTimezoneService = userTimezoneService
        )

        mockMvc = MockMvcBuilders.standaloneSetup(controller)
            .setControllerAdvice(GlobalExceptionHandler())
            .build()
    }

    // AC-B01: GET /api/v1/schedule/{date}
    @Test
    fun `getSchedule returns 200 OK with ScheduleGraphResponse`() {
        val graphResponse = ScheduleGraphResponse(
            date = date.toString(),
            wakeTime = "06:30",
            targetBedtime = "22:30",
            projectedBedtime = "22:30",
            overflowMinutes = 0,
            phases = emptyList(),
            nodes = emptyList(),
            edges = emptyList()
        )
        `when`(scheduleService.getSchedule(userId, date)).thenReturn(graphResponse)

        mockMvc.perform(get("/api/v1/schedule/2026-11-11"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.date").value("2026-11-11"))
            .andExpect(jsonPath("$.wakeTime").value("06:30"))
            .andExpect(jsonPath("$.targetBedtime").value("22:30"))
            .andExpect(jsonPath("$.projectedBedtime").value("22:30"))
            .andExpect(jsonPath("$.overflowMinutes").value(0))
    }

    // AC-B03: POST /api/v1/schedule/habits/{id}/toggle
    @Test
    fun `toggleHabit returns 200 OK with ToggleHabitResponse`() {
        val habitId = UUID.randomUUID()
        val toggleResponse = ToggleHabitResponse(
            habitId = habitId,
            completed = true,
            streak = 5,
            history = emptyList(),
            updatedEdges = emptyList(),
            projectedBedtime = "22:30",
            overflowMinutes = 0
        )
        val request = ToggleHabitRequest(date = date)

        `when`(scheduleService.toggleHabit(userId, habitId, date)).thenReturn(toggleResponse)

        mockMvc.perform(
            post("/api/v1/schedule/habits/$habitId/toggle")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isOk)
            .andExpect(jsonPath("$.habitId").value(habitId.toString()))
            .andExpect(jsonPath("$.completed").value(true))
            .andExpect(jsonPath("$.streak").value(5))
    }

    // AC-B06: POST /api/v1/schedule/steps
    @Test
    fun `addStep returns 201 Created with Location header and ScheduleNodeDTO`() {
        val stepId = UUID.randomUUID().toString()
        val request = AddScheduleStepRequest(
            date = date,
            phase = "deep-focus",
            type = "task",
            title = "API Implementation",
            durationMinutes = 60
        )
        val responseNode = ScheduleNodeDTO(
            id = stepId,
            type = "task",
            phase = "deep-focus",
            title = "API Implementation",
            durationMinutes = 60
        )

        `when`(scheduleService.addStep(userId, request)).thenReturn(responseNode)

        mockMvc.perform(
            post("/api/v1/schedule/steps")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(request))
        )
            .andExpect(status().isCreated)
            .andExpect(header().string("Location", "/api/v1/schedule/steps/$stepId"))
            .andExpect(jsonPath("$.id").value(stepId))
            .andExpect(jsonPath("$.title").value("API Implementation"))
            .andExpect(jsonPath("$.phase").value("deep-focus"))
    }

    // AC-B07: DELETE /api/v1/schedule/steps/{id}
    @Test
    fun `deleteStep returns 204 No Content`() {
        val stepId = UUID.randomUUID().toString()
        doNothing().`when`(scheduleService).deleteStep(userId, stepId)

        mockMvc.perform(delete("/api/v1/schedule/steps/$stepId"))
            .andExpect(status().isNoContent)
    }

    // AC-B08: DELETE /api/v1/schedule/steps/{anchorId} returns 400 Bad Request
    @Test
    fun `deleteStep on anchor returns 400 Bad Request with ANCHOR_DELETION_NOT_ALLOWED`() {
        doThrow(AnchorDeletionNotAllowedException("Anchor node deletion is not allowed"))
            .`when`(scheduleService).deleteStep(userId, "anchor-wake")

        mockMvc.perform(delete("/api/v1/schedule/steps/anchor-wake"))
            .andExpect(status().isBadRequest)
            .andExpect(jsonPath("$.code").value("ANCHOR_DELETION_NOT_ALLOWED"))
    }

    // AC-B09: DELETE /api/v1/schedule/steps/{id} not found returns 404 Not Found
    @Test
    fun `deleteStep not found returns 404 Not Found`() {
        val nonExistentId = UUID.randomUUID().toString()
        doThrow(ScheduleNodeNotFoundException("Schedule node not found: $nonExistentId"))
            .`when`(scheduleService).deleteStep(userId, nonExistentId)

        mockMvc.perform(delete("/api/v1/schedule/steps/$nonExistentId"))
            .andExpect(status().isNotFound)
            .andExpect(jsonPath("$.code").value("NOT_FOUND"))
    }
}
