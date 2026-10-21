import AppKit
import Charts
import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var store: TaskStore
    @AppStorage("activityDays") private var days = 14
    @State private var selectedDay: Date?
    @State private var selection = Set<UUID>()
    @State private var editing: ActivityEvent?

    private var counts: [DailyCount] { dailyCounts(store.events, days: days) }

    private var dayRange: ClosedRange<Date> {
        let cal = Calendar.current
        let last = cal.startOfDay(for: Date())
        let first = cal.date(byAdding: .day, value: -(days - 1), to: last)!
        // Each bar spans its whole day, so the axis runs to the end of today.
        return first...cal.date(byAdding: .day, value: 1, to: last)!
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Activity").font(.headline)
                Spacer()
                Picker("Range", selection: $days) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }
            .padding([.horizontal, .top], 12)

            summary
                .padding(.horizontal, 12)
                .padding(.top, 6)

            chart
                .frame(height: 170)
                .padding(.horizontal, 12)
                .padding(.top, 16)
                .padding(.bottom, 8)

            ActivityLegend()
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

            Divider()
            timeline
        }
        .background(Theme.background)
        .sheet(item: $editing) { event in
            EventEditor(event: event) { store.updateEvent($0) }
        }
    }

    private var summary: some View {
        let done = completedCounts(store.events)
        return Text("Completed today: **\(done.today)** · this week: **\(done.week)**")
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    private var chart: some View {
        Chart {
            ForEach(counts) { c in
                BarMark(x: .value("Day", c.day, unit: .day),
                        y: .value("Actions", c.count),
                        width: .ratio(0.6))
                    .foregroundStyle(by: .value("Action", c.kind.name))
            }
            if let selectedDay, let tip = tooltip(for: selectedDay) {
                RuleMark(x: .value("Day", selectedDay, unit: .day))
                    .foregroundStyle(Color.secondary.opacity(0.25))
                    .annotation(position: .top, overflowResolution: .init(x: .fit, y: .disabled)) {
                        tip
                    }
            }
        }
        .chartForegroundStyleScale(domain: ActivityEvent.Kind.allCases.map(\.name),
                                   range: ActivityEvent.Kind.allCases.map(\.color))
        .chartLegend(.hidden)
        .chartXScale(domain: dayRange)
        .chartXAxis {
            AxisMarks(values: axisDays) {
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.2))
                AxisValueLabel()
            }
        }
        .chartXSelection(value: $selectedDay)
        .overlay {
            if counts.isEmpty {
                Text("No activity in this range").foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel("Actions per day for the last \(days) days")
    }

    /// Label every day, every other day or weekly, skipping a weekly label that would be cut off at the edge.
    private var axisDays: [Date] {
        let step = days > 14 ? 7 : (days > 7 ? 2 : 1)
        let cal = Calendar.current
        let first = dayRange.lowerBound
        return stride(from: 0, to: days, by: step)
            .filter { step < 7 || $0 <= days - 3 }
            .compactMap { cal.date(byAdding: .day, value: $0, to: first) }
    }

    private func tooltip(for date: Date) -> AnyView? {
        let day = Calendar.current.startOfDay(for: date)
        let rows = counts.filter { $0.day == day }
        guard !rows.isEmpty else { return nil }
        return AnyView(
            VStack(alignment: .leading, spacing: 2) {
                Text(day, format: .dateTime.weekday(.wide).month().day()).font(.caption.bold())
                ForEach(rows) { r in
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2).fill(r.kind.color).frame(width: 8, height: 8)
                        Text("\(r.kind.name) \(r.count)")
                    }
                    .font(.caption)
                }
            }
            .padding(6)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
        )
    }

    private var timeline: some View {
        let byDay = Dictionary(grouping: store.events) { Calendar.current.startOfDay(for: $0.date) }
        return Group {
            if store.events.isEmpty {
                VStack { Spacer(); Text("Nothing yet").foregroundStyle(.secondary); Spacer() }
                    .frame(maxWidth: .infinity)
            } else {
                // Day headers are ordinary rows rather than List sections: section headers stay pinned
                // while scrolling and can hide the row beneath them.
                List(selection: $selection) {
                    ForEach(byDay.keys.sorted(by: >), id: \.self) { day in
                        Text(day.formatted(.dateTime.weekday(.wide).month().day()))
                            .font(.callout.bold())
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                            .selectionDisabled()
                        ForEach(byDay[day]!.sorted { $0.date > $1.date }) { event in
                            EventRow(event: event).tag(event.id)
                        }
                    }
                }
                .contextMenu(forSelectionType: UUID.self) { ids in
                    if ids.count == 1, let event = store.events.first(where: { $0.id == ids.first }) {
                        Button("Edit…") { editing = event }
                    }
                    if !ids.isEmpty {
                        Button(ids.count == 1 ? "Delete from History" : "Delete \(ids.count) from History",
                               role: .destructive) { store.deleteEvents(ids) }
                    }
                } primaryAction: { ids in
                    if ids.count == 1, let event = store.events.first(where: { $0.id == ids.first }) {
                        editing = event
                    }
                }
                .onDeleteCommand { store.deleteEvents(selection) }
                .scrollContentBackground(.hidden)
            }
        }
    }
}

/// Edits one history entry: what was done, to which task, when, and its tags.
struct EventEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: ActivityEvent
    @State private var tagText: String
    let onSave: (ActivityEvent) -> Void

    init(event: ActivityEvent, onSave: @escaping (ActivityEvent) -> Void) {
        _draft = State(initialValue: event)
        _tagText = State(initialValue: event.tags.joined(separator: ", "))
        self.onSave = onSave
    }

    var body: some View {
        Form {
            TextField("Task", text: $draft.taskTitle)
            Picker("Action", selection: $draft.kind) {
                ForEach(ActivityEvent.Kind.allCases) { Text($0.name).tag($0) }
            }
            if draft.kind == .priorityChanged {
                Picker("New priority", selection: Binding(
                    get: { draft.detail ?? Priority.none.name },
                    set: { draft.detail = $0 }
                )) {
                    ForEach(Priority.allCases.reversed()) { Text($0.name).tag($0.name) }
                }
            }
            DatePicker("When", selection: $draft.date, in: ...Date())
            TextField("Tags", text: $tagText, prompt: Text("Comma separated"))
        }
        .formStyle(.grouped)
        .frame(width: 360)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    var edited = draft
                    if edited.kind != .priorityChanged { edited.detail = nil }
                    edited.tags = tagText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    onSave(edited)
                    dismiss()
                }
                .disabled(draft.taskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}

struct EventRow: View {
    let event: ActivityEvent

    var body: some View {
        HStack(spacing: 8) {
            Text(event.date, format: .dateTime.hour().minute())
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .leading)
            Image(systemName: event.kind.symbol).foregroundStyle(event.kind.color)
            Text(event.kind.name)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            Text(event.taskTitle).lineLimit(1)
            if let detail = event.detail {
                Text("→ \(detail)").foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            TagChips(tags: event.tags)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Key for the chart: each action's color plus its symbol, so color is never the only cue.
struct ActivityLegend: View {
    var body: some View {
        HStack(spacing: 10) {
            ForEach(ActivityEvent.Kind.allCases) { kind in
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 2).fill(kind.color).frame(width: 8, height: 8)
                    Text(kind.name)
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

extension ActivityEvent.Kind {
    /// Validated categorical palette (slots 1–5), stepped separately for light and dark.
    var color: Color {
        let (light, dark): (UInt32, UInt32) = switch self {
        case .added: (0x2a78d6, 0x3987e5)
        case .completed: (0xeb6834, 0xd95926)
        case .deleted: (0x1baf7a, 0x199e70)
        case .uncompleted: (0xeda100, 0xc98500)
        case .priorityChanged: (0xe87ba4, 0xd55181)
        }
        return Color(nsColor: NSColor(name: nil) { appearance in
            let hex = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
                           green: CGFloat((hex >> 8) & 0xff) / 255,
                           blue: CGFloat(hex & 0xff) / 255, alpha: 1)
        })
    }
}
