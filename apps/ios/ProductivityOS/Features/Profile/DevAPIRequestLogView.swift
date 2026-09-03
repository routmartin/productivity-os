import SwiftUI

/// DevTools: Network tab — a single-screen inspector for every API call the
/// app makes, modeled after the browser Network panel.
///
/// Three layers:
/// 1. `DevAPIRequestLogView` (root) — filter chips, search, list of entries.
/// 2. `DevAPIRequestRow` — one row per HTTP call: method + status pill +
///    path + duration. Color-coded by status family.
/// 3. `DevAPIRequestDetailView` — drill-down: overview, request & response
///    headers, body, and timing. Pretty-prints JSON, supports copy/share.
public struct DevAPIRequestLogView: View {
    @StateObject private var store = APILogStore.shared
    @State private var selectedFamily: APILogStore.StatusFamily = .all
    @State private var query: String = ""
    @State private var selectedEntry: APILogStore.Entry?

    public init() {}

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle("Network")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $query, prompt: "Search path, status, body")
                .toolbar { toolbar }
                .sheet(item: $selectedEntry) { entry in
                    DevAPIRequestDetailView(entry: entry)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        let entries = store.filtered(family: selectedFamily, query: query)
        VStack(spacing: 0) {
            filterBar
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.xs)
            Divider().background(AppColors.surfaceBorder)
            if entries.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(entries) { entry in
                        DevAPIRequestRow(entry: entry)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedEntry = entry }
                            .listRowSeparatorTint(AppColors.surfaceBorder)
                            .listRowInsets(EdgeInsets(
                                top: AppSpacing.xs,
                                leading: AppSpacing.md,
                                bottom: AppSpacing.xs,
                                trailing: AppSpacing.md
                            ))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(AppColors.canvas.ignoresSafeArea())
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(APILogStore.StatusFamily.allCases) { family in
                    let count = store.count(for: family)
                    let isActive = family == selectedFamily
                    Button {
                        selectedFamily = family
                    } label: {
                        HStack(spacing: 6) {
                            Text(family.title)
                                .font(AppTypography.caption)
                                .fontWeight(.semibold)
                            Text("\(count)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(isActive
                                                   ? Color.white.opacity(0.25)
                                                   : AppColors.canvasSecondary)
                                )
                        }
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, 6)
                        .foregroundStyle(isActive ? Color.white : AppColors.textPrimary)
                        .background(
                            Capsule().fill(isActive ? AppColors.primary : AppColors.surface)
                        )
                        .overlay(
                            Capsule().stroke(isActive ? Color.clear : AppColors.surfaceBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Spacer()
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(AppColors.textTertiary)
            Text("No requests yet")
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)
            Text("Use the app — every API call will show up here.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(AppSpacing.lg)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button(role: .destructive) {
                    store.clear()
                } label: {
                    Label("Clear all", systemImage: "trash")
                }
                .disabled(store.logEntries.isEmpty)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(AppColors.primary)
            }
        }
    }
}

// MARK: - Row

private struct DevAPIRequestRow: View {
    let entry: APILogStore.Entry

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            methodPill
            VStack(alignment: .leading, spacing: 4) {
                Text(displayPath)
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(detailLine)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: AppSpacing.xs)
            statusBadge
        }
        .padding(.vertical, AppSpacing.xxs)
    }

    private var methodPill: some View {
        Text(entry.method)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .tracking(0.4)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(width: 56, alignment: .center)
            .foregroundStyle(methodColor)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(methodColor.opacity(0.12))
            )
    }

    private var statusBadge: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if let code = entry.statusCode {
                Text("\(code)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(statusColor(for: code))
            } else if entry.phase == .pending {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 36, height: 18)
            } else {
                Text("ERR")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppColors.textSecondary)
            }
            if let duration = entry.durationMs {
                Text(format(durationMs: duration))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .frame(minWidth: 44, alignment: .trailing)
    }

    private var displayPath: String {
        if let query = entry.query, !query.isEmpty {
            return "\(entry.path)?\(query)"
        }
        return entry.path
    }

    private var detailLine: String {
        let started = entry.startedAt.formatted(date: .omitted, time: .standard)
        let host = entry.host.isEmpty ? "—" : entry.host
        return "\(started) · \(host)"
    }

    private var methodColor: Color {
        switch entry.method {
        case "GET": return AppColors.primary
        case "POST": return AppColors.success
        case "PUT", "PATCH": return AppColors.priorityMediumText
        case "DELETE": return AppColors.priorityHighText
        default: return AppColors.textSecondary
        }
    }

    private func statusColor(for code: Int) -> Color {
        switch code {
        case 200...299: return AppColors.success
        case 300...399: return AppColors.primary
        case 400...499: return AppColors.priorityMediumText
        case 500...599: return AppColors.priorityHighText
        default: return AppColors.textSecondary
        }
    }

    private func format(durationMs: Int) -> String {
        if durationMs < 1000 {
            return "\(durationMs) ms"
        }
        let seconds = Double(durationMs) / 1000.0
        return String(format: "%.2f s", seconds)
    }
}

// MARK: - Detail

private struct DevAPIRequestDetailView: View {
    let entry: APILogStore.Entry
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var isRequestBodyExpanded = true
    @State private var isResponseBodyExpanded = true
    @State private var justCopied: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    overview
                    timingSection
                    requestHeadersSection
                    requestBodySection
                    responseHeadersSection
                    responseBodySection
                    if let error = entry.errorDescription {
                        errorSection(error)
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(AppColors.canvas.ignoresSafeArea())
            .navigationTitle("Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(AppColors.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(AppColors.primary)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [shareText])
            }
        }
    }

    private var overview: some View {
        AppCard(cornerRadius: AppRadius.lg) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.xs) {
                    Text(entry.method)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(0.5)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(AppColors.primary)
                        .background(
                            Capsule().fill(AppColors.primaryTint)
                        )
                    if let code = entry.statusCode {
                        Text("HTTP \(code)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(statusColor(for: code))
                    } else if entry.phase == .failure {
                        Text("Failed")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColors.priorityHighText)
                    } else {
                        Text("Pending")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
                Text(entry.path)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(AppColors.textPrimary)
                    .textSelection(.enabled)
                if let q = entry.query, !q.isEmpty {
                    Text("?\(q)")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(AppColors.textSecondary)
                        .textSelection(.enabled)
                }
                if !entry.host.isEmpty {
                    Text(entry.host)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
        }
    }

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeaderView(title: "Timing")
            AppCard(cornerRadius: AppRadius.md) {
                HStack(spacing: AppSpacing.lg) {
                    metric(label: "Started", value: entry.startedAt.formatted(date: .omitted, time: .standard))
                    metric(
                        label: "Duration",
                        value: entry.durationMs.map { format(durationMs: $0) } ?? "—"
                    )
                    metric(
                        label: "Phase",
                        value: entry.phase == .success ? "OK" : (entry.phase == .failure ? "Fail" : "…")
                    )
                }
            }
        }
    }

    private var requestHeadersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeaderView(title: "Request headers")
            headersCard(headers: entry.requestHeaders)
        }
    }

    private var requestBodySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            collapsibleSectionHeader(
                title: "Request body",
                isExpanded: $isRequestBodyExpanded,
                bodyText: entry.requestBody?.displayString,
                copyKey: "request"
            )
            if isRequestBodyExpanded {
                bodyCard(body: entry.requestBody, emptyMessage: "(none)")
            }
        }
    }

    private var responseHeadersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeaderView(title: "Response headers")
            if let headers = entry.responseHeaders {
                headersCard(headers: headers)
            } else {
                placeholderCard("(no response)")
            }
        }
    }

    private var responseBodySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            collapsibleSectionHeader(
                title: "Response body",
                isExpanded: $isResponseBodyExpanded,
                bodyText: entry.responseBody?.displayString,
                copyKey: "response"
            )
            if isResponseBodyExpanded {
                bodyCard(body: entry.responseBody, emptyMessage: "(empty)")
            }
        }
    }

    private func errorSection(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            SectionHeaderView(title: "Error")
            AppCard(cornerRadius: AppRadius.md) {
                Text(message)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(AppColors.priorityHighText)
                    .textSelection(.enabled)
            }
        }
    }

    /// Header row that combines the section title, a chevron toggle for
    /// collapsing the body, and a copy-to-clipboard button. The copy
    /// button is disabled when the body is empty.
    private func collapsibleSectionHeader(
        title: String,
        isExpanded: Binding<Bool>,
        bodyText: String?,
        copyKey: String
    ) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Button {
                withAnimation(.easeOut(duration: 0.18)) {
                    isExpanded.wrappedValue.toggle()
                }
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                        .foregroundStyle(AppColors.primary)
                    Text(title.uppercased())
                        .font(AppTypography.sectionHeader)
                        .foregroundStyle(AppColors.primary)
                        .tracking(0.8)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            copyButton(text: bodyText ?? "", copyKey: copyKey)
        }
        .padding(.horizontal, 4)
    }

    private func copyButton(text: String, copyKey: String) -> some View {
        let isEmpty = text.isEmpty
        let justCopiedThis = justCopied == copyKey
        return Button {
            copyToClipboard(text, copyKey: copyKey)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: justCopiedThis ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11, weight: .bold))
                Text(justCopiedThis ? "Copied" : "Copy")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(justCopiedThis ? AppColors.success : (isEmpty ? AppColors.textTertiary : AppColors.primary))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(
                    justCopiedThis
                        ? AppColors.successTint
                        : (isEmpty ? AppColors.canvasSecondary : AppColors.primaryTint)
                )
            )
        }
        .buttonStyle(.plain)
        .disabled(isEmpty)
    }

    private func copyToClipboard(_ text: String, copyKey: String) {
        UIPasteboard.general.string = text
        justCopied = copyKey
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            if justCopied == copyKey {
                justCopied = nil
            }
        }
    }

    private func headersCard(headers: [String: String]) -> some View {
        AppCard(cornerRadius: AppRadius.md) {
            if headers.isEmpty {
                Text("(none)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(AppColors.textTertiary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(headers.keys.sorted(), id: \.self) { key in
                        HStack(alignment: .top, spacing: AppSpacing.xs) {
                            Text(key)
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.textPrimary)
                            Text(":")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(AppColors.textTertiary)
                            Text(headers[key] ?? "")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(AppColors.textSecondary)
                                .textSelection(.enabled)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func bodyCard(body: APILogStore.BodyValue?, emptyMessage: String) -> some View {
        AppCard(cornerRadius: AppRadius.md) {
            if let body {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(body.displayString)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(AppColors.textSecondary)
                        .textSelection(.enabled)
                        .padding(.vertical, AppSpacing.xxs)
                }
            } else {
                Text(emptyMessage)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }

    private func placeholderCard(_ text: String) -> some View {
        AppCard(cornerRadius: AppRadius.md) {
            Text(text)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(AppColors.textTertiary)
        }
    }

    private func metric(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(AppColors.textTertiary)
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .fontWeight(.medium)
                .foregroundStyle(AppColors.textPrimary)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var shareText: String {
        var lines: [String] = []
        lines.append("\(entry.method) \(entry.path)")
        if let code = entry.statusCode { lines.append("HTTP \(code)") }
        if let ms = entry.durationMs { lines.append("Duration: \(ms) ms") }
        if let body = entry.responseBody {
            lines.append("")
            lines.append("Response:")
            lines.append(body.displayString)
        }
        if let error = entry.errorDescription {
            lines.append("")
            lines.append("Error: \(error)")
        }
        return lines.joined(separator: "\n")
    }

    private func statusColor(for code: Int) -> Color {
        switch code {
        case 200...299: return AppColors.success
        case 300...399: return AppColors.primary
        case 400...499: return AppColors.priorityMediumText
        case 500...599: return AppColors.priorityHighText
        default: return AppColors.textSecondary
        }
    }

    private func format(durationMs: Int) -> String {
        if durationMs < 1000 {
            return "\(durationMs) ms"
        }
        let seconds = Double(durationMs) / 1000.0
        return String(format: "%.2f s", seconds)
    }
}

// MARK: - Share

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DevAPIRequestLogView()
}