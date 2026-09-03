import SwiftUI

/// Edit sheet for a single task. Mirrors the web Tasks edit flow (title,
/// description, priority, energy, estimated duration) so changes made on
/// iOS stay in sync with the backend and reflect back in the web app.
///
/// Duration is stored on the backend as a positive integer of minutes
/// (no fixed set of allowed values — the field is free-form on the API
/// side). To keep web and iOS in perfect sync the sheet uses a free-form
/// number field for the value and exposes the web's preset options
/// (15/30/45/60/90/120) as a "Quick set" menu for one-tap selection.
public struct TaskEditSheet: View {
    private let task: TaskItem
    private let onSaved: (TaskItem) -> Void
    private let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var description: String
    @State private var priority: TaskPriority?
    @State private var energy: TaskEnergy?
    @State private var durationText: String
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?

    private let taskService: TaskService

    public init(
        task: TaskItem,
        taskService: TaskService = TaskService(),
        onSaved: @escaping (TaskItem) -> Void = { _ in },
        onDismiss: @escaping () -> Void = {}
    ) {
        self.task = task
        self.taskService = taskService
        self.onSaved = onSaved
        self.onDismiss = onDismiss
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description ?? "")
        _priority = State(initialValue: task.priority)
        _energy = State(initialValue: task.energy)
        _durationText = State(
            initialValue: task.estimatedDurationMinutes.map(String.init) ?? ""
        )
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Task title", text: $title)
                }

                Section("Description") {
                    TextField("Optional details", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Priority") {
                    Picker("Priority", selection: priorityBinding) {
                        Text("None").tag(TaskPriority?.none)
                        ForEach(TaskPriority.allCases, id: \.self) { value in
                            Text(value.title).tag(TaskPriority?.some(value))
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Energy") {
                    Picker("Energy", selection: energyBinding) {
                        Text("None").tag(TaskEnergy?.none)
                        ForEach(TaskEnergy.allCases, id: \.self) { value in
                            Text(value.rawValue.capitalized).tag(TaskEnergy?.some(value))
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    HStack(alignment: .firstTextBaseline) {
                        TextField("e.g. 45", text: $durationText)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.leading)
                            #endif
                        Text("min")
                            .foregroundStyle(AppColors.textSecondary)
                        Spacer()
                        if let formatted = formattedDuration {
                            Text(formatted)
                                .font(AppTypography.subheadline)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                } header: {
                    Text("Estimated duration")
                } footer: {
                    Text("Match the value you set on web — any positive number of minutes works.")
                }

                Section("Quick set") {
                    HStack(spacing: AppSpacing.xs) {
                        ForEach(quickPresets, id: \.self) { preset in
                            Button {
                                durationText = String(preset)
                            } label: {
                                Text(presetLabel(preset))
                                    .font(AppTypography.captionSmall)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 32)
                                    .background(isSelected(preset) ? AppColors.primaryTint : AppColors.surface)
                                    .foregroundStyle(isSelected(preset) ? AppColors.primary : AppColors.textPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                            .stroke(isSelected(preset) ? AppColors.primary : AppColors.surfaceBorder, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button(role: .destructive) {
                        durationText = ""
                    } label: {
                        Label("Clear estimate", systemImage: "xmark.circle")
                    }
                    .disabled(durationText.isEmpty)
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color(hex: "FF6B4A"))
                            .font(AppTypography.caption)
                    }
                }
            }
            .navigationTitle("Edit Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSubmitting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(isSubmitting || title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .overlay {
                if isSubmitting {
                    ProgressView()
                }
            }
        }
    }

    private var priorityBinding: Binding<TaskPriority?> {
        Binding(get: { priority }, set: { priority = $0 })
    }

    private var energyBinding: Binding<TaskEnergy?> {
        Binding(get: { energy }, set: { energy = $0 })
    }

    private let quickPresets: [Int] = [15, 30, 45, 60, 90, 120]

    private func presetLabel(_ minutes: Int) -> String {
        if minutes < 60 { return "\(minutes)m" }
        let h = minutes / 60
        let m = minutes % 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }

    private func isSelected(_ preset: Int) -> Bool {
        durationText == String(preset)
    }

    private var parsedDuration: Int? {
        let trimmed = durationText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let value = Int(trimmed), value > 0 else { return nil }
        return value
    }

    private var formattedDuration: String? {
        guard let minutes = parsedDuration else { return nil }
        return presetLabel(minutes)
    }

    private func save() async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = description.trimmingCharacters(in: .whitespaces)
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        do {
            let updated = try await taskService.updateTask(
                id: task.id,
                title: trimmedTitle.isEmpty ? nil : trimmedTitle,
                description: trimmedDescription.isEmpty ? nil : trimmedDescription,
                priority: priority,
                energy: energy,
                estimatedDurationMinutes: parsedDuration
            )
            onSaved(updated)
            dismiss()
        } catch {
            errorMessage = FocusSessionViewModel.userMessage(for: error)
        }
    }
}

#Preview {
    TaskEditSheet(task: TaskItem(title: "Sample", estimatedDurationMinutes: 45))
}
