import SwiftUI

/// Dedicated editing sheet to modify an existing schedule step (Spec AC-010, AC-012).
public struct ScheduleEditStepSheet: View {
    @Environment(\.dismiss) private var dismiss

    public let node: ScheduleNode
    public var onSave: (UpdateStepPayload) -> Void

    @State private var selectedPhase: SchedulePhaseId
    @State private var title: String
    @State private var subtitle: String
    @State private var timeSlot: String
    @State private var selectedDuration: Int
    @State private var notes: String
    @State private var selectedIcon: String

    private let durationOptions = [5, 10, 15, 30, 45, 60, 90, 120]
    private let habitIcons = [
        "drop.fill", "figure.run", "shower.fill", "target",
        "book.fill", "moon.fill", "cup.and.saucer.fill", "heart.fill",
        "dumbbell.fill", "figure.walk", "leaf.fill", "sparkles"
    ]

    public init(
        node: ScheduleNode,
        onSave: @escaping (UpdateStepPayload) -> Void
    ) {
        self.node = node
        self.onSave = onSave
        self._selectedPhase = State(initialValue: node.phase)
        self._title = State(initialValue: node.title)
        self._subtitle = State(initialValue: node.subtitle ?? "")
        self._timeSlot = State(initialValue: node.time ?? node.targetTime ?? "")
        let initialDuration = node.durationMinutes ?? node.totalMinutes ?? 15
        self._selectedDuration = State(initialValue: initialDuration)
        self._notes = State(initialValue: node.notes ?? "")
        self._selectedIcon = State(initialValue: node.icon ?? "drop.fill")
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Phase") {
                    Picker("Target Phase", selection: $selectedPhase) {
                        ForEach(SchedulePhaseId.allCases, id: \.self) { phase in
                            Text(phase.defaultTitle).tag(phase)
                        }
                    }
                }

                Section("Details") {
                    TextField("Title", text: $title)

                    TextField("Subtitle (optional)", text: $subtitle)

                    TextField("Scheduled Time (e.g. 09:30)", text: $timeSlot)
                }

                Section("Duration") {
                    Picker("Duration", selection: $selectedDuration) {
                        ForEach(durationOptions, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Protocol Notes") {
                    TextField("Protocol notes or execution details", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if node.type == .habit {
                    Section("Habit Icon") {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                            spacing: 10
                        ) {
                            ForEach(habitIcons, id: \.self) { icon in
                                Button {
                                    withAnimation(AppMotion.micro) {
                                        selectedIcon = icon
                                    }
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(selectedIcon == icon ? AppColors.primary : Color(hex: "F1F5F9"))
                                            .frame(height: 44)

                                        Image(systemName: icon)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(selectedIcon == icon ? .white : AppColors.textPrimary)
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Edit Step")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let payload = UpdateStepPayload(
                            title: title,
                            subtitle: subtitle.isEmpty ? nil : subtitle,
                            phaseId: selectedPhase,
                            timeSlot: timeSlot.isEmpty ? nil : timeSlot,
                            durationMinutes: selectedDuration,
                            notes: notes.isEmpty ? nil : notes,
                            iconName: node.type == .habit ? selectedIcon : nil
                        )
                        onSave(payload)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!isValid)
                }
            }
        }
    }
}
