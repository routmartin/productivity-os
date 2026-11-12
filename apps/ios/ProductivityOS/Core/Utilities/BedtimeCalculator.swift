import Foundation

/// Pure domain calculation engine for dynamic bedtime projections (Spec AC-004).
public enum BedtimeCalculator {
    public struct Result: Sendable, Hashable {
        public let overflowMinutes: Int
        public let projectedBedtime: String
        public let targetBedtime: String
        public let isOverflowing: Bool
        public let statusMessage: String

        public init(
            overflowMinutes: Int,
            projectedBedtime: String,
            targetBedtime: String
        ) {
            self.overflowMinutes = overflowMinutes
            self.projectedBedtime = projectedBedtime
            self.targetBedtime = targetBedtime
            self.isOverflowing = overflowMinutes > 0
            if overflowMinutes > 0 {
                self.statusMessage = "Schedule overflow: Bedtime shifts by \(overflowMinutes)m"
            } else {
                self.statusMessage = "On track for \(targetBedtime) bedtime"
            }
        }
    }

    public static func calculate(
        targetBedtime: String = "22:30",
        nodes: [ScheduleNode]
    ) -> Result {
        let habitNodes = nodes.filter { $0.type == .habit }
        let taskNodes = nodes.filter { $0.type == .task }

        let pendingHabits = habitNodes.filter { !($0.completed ?? false) }.count
        let incompleteTasks = taskNodes.filter { ($0.completedMinutes ?? 0) < ($0.totalMinutes ?? 60) }.count

        var overflow = 0
        if pendingHabits > 0 || incompleteTasks > 0 {
            overflow = min(45, (pendingHabits + incompleteTasks) * 15)
        }

        let parts = targetBedtime.split(separator: ":").compactMap { Int($0) }
        let targetHour = parts.indices.contains(0) ? parts[0] : 22
        let targetMinute = parts.indices.contains(1) ? parts[1] : 30

        let totalTargetMinutes = targetHour * 60 + targetMinute + overflow
        let projectedHour = (totalTargetMinutes / 60) % 24
        let projectedMinute = totalTargetMinutes % 60

        let formattedTime = String(format: "%02d:%02d", projectedHour, projectedMinute)

        return Result(
            overflowMinutes: overflow,
            projectedBedtime: formattedTime,
            targetBedtime: targetBedtime
        )
    }
}
