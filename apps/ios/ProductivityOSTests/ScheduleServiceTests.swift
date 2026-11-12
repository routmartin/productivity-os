import Foundation
import XCTest
@testable import ProductivityOS

final class ScheduleServiceTests: XCTestCase {
    private var mockAPIClient: MockAPIClient!
    private var scheduleService: ScheduleService!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockAPIClient()
        scheduleService = ScheduleService(apiClient: mockAPIClient)
    }

    private var sampleDate: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 11
        components.day = 12
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    // MARK: - AC-C06: Load Schedule Tests

    func testLoadScheduleSuccess() async throws {
        let scheduleJSON = """
        {
            "date": "2026-11-12",
            "wakeTime": "06:30",
            "targetBedtime": "22:30",
            "projectedBedtime": "22:30",
            "overflowMinutes": 0,
            "phases": [
                {
                    "id": "morning",
                    "title": "Morning Activation",
                    "subtitle": "Rise, hydrate, move",
                    "timeRange": "06:30 – 09:00",
                    "colorTone": "warning"
                }
            ],
            "nodes": [
                {
                    "id": "anchor-wake",
                    "type": "anchor",
                    "phase": "morning",
                    "title": "Wake Up",
                    "order": 1
                }
            ],
            "edges": []
        }
        """
        mockAPIClient.scriptedResponses = [
            .success((Data(scheduleJSON.utf8), 200))
        ]

        let graph = try await scheduleService.loadSchedule(for: sampleDate)

        XCTAssertEqual(graph.date, "2026-11-12")
        XCTAssertEqual(graph.wakeTime, "06:30")
        XCTAssertEqual(graph.targetBedtime, "22:30")
        XCTAssertEqual(graph.phases.count, 1)
        XCTAssertEqual(graph.nodes.count, 1)
        XCTAssertEqual(graph.nodes.first?.id, "anchor-wake")

        let request = try XCTUnwrap(mockAPIClient.recordedRequests.first)
        XCTAssertEqual(request.method, "GET")
        XCTAssertEqual(request.path, "/api/v1/schedule/2026-11-12")
    }

    func testLoadScheduleFallsBackToDefaultBlueprintOnNetworkError() async throws {
        mockAPIClient.scriptedResponses = [
            .failure(APIError.networkError("The Internet connection appears to be offline."))
        ]

        let graph = try await scheduleService.loadSchedule(for: sampleDate)

        // Fallback returns 16-node baseline blueprint
        XCTAssertEqual(graph.date, "2026-11-12")
        XCTAssertEqual(graph.phases.count, 4)
        XCTAssertEqual(graph.nodes.count, 16)
        XCTAssertEqual(graph.edges.count, 15)
        XCTAssertEqual(graph.wakeTime, "06:30")
        XCTAssertEqual(graph.targetBedtime, "22:30")

        let request = try XCTUnwrap(mockAPIClient.recordedRequests.first)
        XCTAssertEqual(request.path, "/api/v1/schedule/2026-11-12")
    }

    func testLoadScheduleThrowsOnUnauthorized() async throws {
        mockAPIClient.scriptedResponses = [
            .failure(APIError.unauthorized(code: "token_expired", message: nil))
        ]

        do {
            _ = try await scheduleService.loadSchedule(for: sampleDate)
            XCTFail("Expected unauthorized error to be rethrown")
        } catch let error as APIError {
            if case .unauthorized = error {
                // expected
            } else {
                XCTFail("Expected .unauthorized, got \(error)")
            }
        }
    }

    // MARK: - AC-C07: Toggle Habit Tests

    func testToggleHabitSendsCorrectEndpointAndPayload() async throws {
        let habitUUID = UUID()
        let responseJSON = """
        {
            "habitId": "\(habitUUID.uuidString)",
            "completed": true,
            "streak": 13,
            "history": [
                { "date": "2026-11-12", "completed": true }
            ],
            "updatedEdges": [
                {
                    "id": "e-test",
                    "fromNodeId": "\(habitUUID.uuidString)",
                    "toNodeId": "next-node",
                    "type": "sequential",
                    "active": true
                }
            ],
            "projectedBedtime": "22:30",
            "overflowMinutes": 0
        }
        """
        mockAPIClient.scriptedResponses = [
            .success((Data(responseJSON.utf8), 200))
        ]

        let response = try await scheduleService.toggleHabit(habitId: habitUUID, for: sampleDate)

        XCTAssertEqual(response.habitId, habitUUID)
        XCTAssertTrue(response.completed)
        XCTAssertEqual(response.streak, 13)
        XCTAssertEqual(response.history.count, 1)
        XCTAssertEqual(response.updatedEdges.count, 1)

        let request = try XCTUnwrap(mockAPIClient.recordedRequests.first)
        XCTAssertEqual(request.method, "POST")
        XCTAssertEqual(request.path, "/api/v1/schedule/habits/\(habitUUID.uuidString.lowercased())/toggle")

        // Body must carry date
        let body = try XCTUnwrap(request.body)
        let decodedBody = try JSONDecoder().decode(ToggleHabitRequestBody.self, from: body)
        XCTAssertEqual(decodedBody.date, "2026-11-12")
    }

    // MARK: - AC-C08: Add Step & Delete Step Tests

    func testAddStepCorrectlySerializesPayloadAndReturnsNode() async throws {
        let nodeUUID = UUID()
        let responseJSON = """
        {
            "id": "\(nodeUUID.uuidString)",
            "type": "habit",
            "phase": "morning",
            "title": "Cold Brew & Sunlight",
            "subtitle": "Morning stack",
            "durationMinutes": 20,
            "streak": 1,
            "completed": false,
            "order": 5
        }
        """
        mockAPIClient.scriptedResponses = [
            .success((Data(responseJSON.utf8), 201))
        ]

        let payload = AddStepPayload(
            phaseId: .morning,
            type: .habit,
            title: "Cold Brew & Sunlight",
            subtitle: "Morning stack",
            totalMinutes: 20,
            iconName: "cup.and.saucer.fill"
        )

        let createdNode = try await scheduleService.addStep(payload, for: sampleDate)

        XCTAssertEqual(createdNode.id, nodeUUID.uuidString)
        XCTAssertEqual(createdNode.title, "Cold Brew & Sunlight")
        XCTAssertEqual(createdNode.durationMinutes, 20)

        let request = try XCTUnwrap(mockAPIClient.recordedRequests.first)
        XCTAssertEqual(request.method, "POST")
        XCTAssertEqual(request.path, "/api/v1/schedule/steps")

        let body = try XCTUnwrap(request.body)
        let decodedBody = try JSONDecoder().decode(AddScheduleStepRequestBody.self, from: body)
        XCTAssertEqual(decodedBody.date, "2026-11-12")
        XCTAssertEqual(decodedBody.phase, "morning")
        XCTAssertEqual(decodedBody.type, "habit")
        XCTAssertEqual(decodedBody.title, "Cold Brew & Sunlight")
        XCTAssertEqual(decodedBody.durationMinutes, 20)
        XCTAssertEqual(decodedBody.iconName, "cup.and.saucer.fill")
    }

    func testDeleteStepSendsDeleteRequest() async throws {
        mockAPIClient.scriptedResponses = [
            .success((Data(), 204))
        ]

        let stepId = "custom-node-1234"
        try await scheduleService.deleteStep(id: stepId)

        let request = try XCTUnwrap(mockAPIClient.recordedRequests.first)
        XCTAssertEqual(request.method, "DELETE")
        XCTAssertEqual(request.path, "/api/v1/schedule/steps/custom-node-1234")
    }

    // MARK: - AC-010 & AC-011: Update Schedule Step Tests

    func testUpdateStepSuccessEncodesPayloadAndSendsPutRequest() async throws {
        let stepId = "e2a1b9c3-4d5e-6f7a-8b9c-0d1e2f3a4b5c"
        let updatedNodeJSON = """
        {
            "id": "\(stepId)",
            "type": "task",
            "phase": "deep-focus",
            "title": "Deep Focus Architecture & System Design",
            "subtitle": "High cognitive load · Core DB schema",
            "time": "09:30",
            "durationMinutes": 90,
            "totalMinutes": 90,
            "notes": "Ensure all FK constraints and indexes are covered.",
            "order": 6
        }
        """

        mockAPIClient.scriptedResponses = [
            .success((Data(updatedNodeJSON.utf8), 200))
        ]

        let payload = UpdateStepPayload(
            title: "Deep Focus Architecture & System Design",
            subtitle: "High cognitive load · Core DB schema",
            phaseId: .deepFocus,
            timeSlot: "09:30",
            durationMinutes: 90,
            notes: "Ensure all FK constraints and indexes are covered.",
            iconName: "brain.head.profile"
        )

        let result = try await scheduleService.updateStep(id: stepId, payload: payload, for: sampleDate)

        XCTAssertEqual(result.id, stepId)
        XCTAssertEqual(result.title, "Deep Focus Architecture & System Design")
        XCTAssertEqual(result.phase, .deepFocus)
        XCTAssertEqual(result.durationMinutes, 90)
        XCTAssertEqual(result.notes, "Ensure all FK constraints and indexes are covered.")

        let request = try XCTUnwrap(mockAPIClient.recordedRequests.first)
        XCTAssertEqual(request.method, "PUT")
        XCTAssertEqual(request.path, "/api/v1/schedule/steps/\(stepId)")

        let body = try XCTUnwrap(request.body)
        let decodedBody = try JSONDecoder().decode(UpdateScheduleStepRequestBody.self, from: body)
        XCTAssertEqual(decodedBody.title, "Deep Focus Architecture & System Design")
        XCTAssertEqual(decodedBody.subtitle, "High cognitive load · Core DB schema")
        XCTAssertEqual(decodedBody.phase, "deep-focus")
        XCTAssertEqual(decodedBody.timeSlot, "09:30")
        XCTAssertEqual(decodedBody.durationMinutes, 90)
        XCTAssertEqual(decodedBody.notes, "Ensure all FK constraints and indexes are covered.")
        XCTAssertEqual(decodedBody.iconName, "brain.head.profile")
        XCTAssertEqual(decodedBody.date, "2026-11-12")
    }

    func testUpdateStepPropagatesAnchorRejectionError() async throws {
        let errorJSON = """
        {
            "code": "ANCHOR_UPDATE_NOT_ALLOWED",
            "message": "Anchor node update is not allowed",
            "traceId": "7f8a9b0c"
        }
        """

        mockAPIClient.scriptedResponses = [
            .failure(APIError(statusCode: 400, data: Data(errorJSON.utf8)))
        ]

        let payload = UpdateStepPayload(
            title: "Modified Wake Anchor",
            durationMinutes: 30
        )

        do {
            _ = try await scheduleService.updateStep(id: "anchor-wake", payload: payload, for: sampleDate)
            XCTFail("Expected anchor update rejection error")
        } catch let error as APIError {
            XCTAssertEqual(error.errorCode, "ANCHOR_UPDATE_NOT_ALLOWED")
        }
    }
}
