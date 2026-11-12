import SwiftUI

/// In-line creation sheet to insert a new step into the schedule graph (Spec AC-007).
public struct ScheduleAddStepSheet: View {
    @Environment(\.dismiss) private var dismiss

    public var initialPhase: SchedulePhaseId
    public var onAdd: (AddStepPayload) -> Void

    @State private var selectedPhase: SchedulePhaseId
    @State private var selectedType: ScheduleNodeType = .habit
    @State private var title: String = ""
    @State private var subtitle: String = ""
    @State private var selectedDuration: Int = 15
    @State private var selectedIcon: String = "drop.fill"

    private let durationOptions = [15, 30, 45, 60, 90]
    private let habitIcons = [
        "drop.fill", "figure.run", "shower.fill", "target",
        "book.fill", "moon.fill", "cup.and.saucer.fill", "heart.fill",
        "dumbbell.fill", "figure.walk", "leaf.fill", "sparkles"
    ]

    public init(
        initialPhase: SchedulePhaseId = .morning,
        onAdd: @escaping (AddStepPayload) -> Void
    ) {
        self.initialPhase = initialPhase
        self._selectedPhase = State(initialValue: initialPhase)
        self.onAdd = onAdd
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Phase & Step Type") {
                    Picker("Target Phase", selection: $selectedPhase) {
                        ForEach(SchedulePhaseId.allCases, id: \.self) { phase in
                            Text(phase.defaultTitle).tag(phase)
                        }
                    }

                    Picker("Type", selection: $selectedType) {
                        Text("Habit").tag(ScheduleNodeType.habit)
                        Text("Activity").tag(ScheduleNodeType.task)
                        Text("Recharge Break").tag(ScheduleNodeType.recharge)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Details") {
                    TextField(selectedType == .habit ? "Habit Title (e.g. 500ml Water)" : "Activity / Task Title", text: $title)

                    TextField("Subtitle or Notes (optional)", text: $subtitle)
                }

                Section("Duration") {
                    Picker("Duration", selection: $selectedDuration) {
                        ForEach(durationOptions, id: \.self) { minutes in
                            Text("\(minutes) min").tag(minutes)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if selectedType == .habit {
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
            .navigationTitle("Add Schedule Step")
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
                    Button("Add Step") {
                        let payload = AddStepPayload(
                            phaseId: selectedPhase,
                            type: selectedType,
                            title: title,
                            subtitle: subtitle.isEmpty ? nil : subtitle,
                            totalMinutes: selectedDuration,
                            iconName: selectedIcon
                        )
                        onAdd(payload)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(!isValid)
                }
            }
        }
    }
}
