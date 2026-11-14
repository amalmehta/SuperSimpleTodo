import SwiftUI

/// The one-line offer above the list: "Untouched for 30+ days: Fix bike and Learn Rust". Nothing
/// moves until you click Archive Them (⌘Z brings them back); Not Now hides it until another task goes stale.
struct StaleNudge: View {
    let tasks: [TaskItem]
    let onArchive: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label(tasks.count == 1 ? "1 untouched for \(StaleTasks.days)+ days"
                                       : "\(tasks.count) untouched for \(StaleTasks.days)+ days",
                      systemImage: "clock.arrow.circlepath")
                    .labelStyle(NudgeLabelStyle())
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .accessibilityLabel("\(tasks.count) tasks untouched for \(StaleTasks.days) days or more: "
                                        + tasks.map(\.title).joined(separator: ", "))
                Spacer(minLength: 8)
                Button("Not Now", action: onDismiss)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                Button(tasks.count == 1 ? "Archive It" : "Archive Them", action: onArchive)
                    .buttonStyle(.borderless)
                    .fontWeight(.medium)
            }
            Text(StaleTasks.summary(tasks.map(\.title)))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.leading, 22)
                .accessibilityHidden(true)
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: Theme.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).stroke(Color.orange.opacity(0.25)))
        .help(tasks.map(\.title).joined(separator: "\n")
              + "\n\nNot added to, edited or ticked for \(StaleTasks.days) days. Archived tasks keep everything and come back with Restore.")
        .accessibilityElement(children: .contain)
    }
}

private struct NudgeLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundStyle(.orange)
            configuration.title
        }
    }
}

/// An archived task: a restore button, the title (struck through if it was finished), when it was
/// archived, and its tags.
struct ArchiveRow: View {
    let task: TaskItem
    let onRestore: () -> Void

    private var archivedText: String {
        let when = task.archivedAt.map { $0.formatted(.relative(presentation: .named)) } ?? ""
        return task.isDone ? "Done · archived \(when)" : "Archived \(when)"
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Button(action: onRestore) {
                Image(systemName: "arrow.uturn.backward.circle")
                    .foregroundStyle(Color.accentColor)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .help("Restore: back on your list, open")
            .accessibilityLabel("Restore")

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .strikethrough(task.isDone)
                    .foregroundStyle(task.isDone ? .secondary : .primary)
                Text(archivedText)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            if !task.tags.isEmpty {
                Spacer(minLength: 8)
                TagChips(tags: task.tags)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(task.title)
        .accessibilityValue([archivedText, task.tags.isEmpty ? nil : "Tags: \(task.tags.joined(separator: ", "))"]
            .compactMap { $0 }.joined(separator: ". "))
        .accessibilityAction(named: "Restore", onRestore)
    }
}

/// Under the add field: archived tasks that match what you're typing, to bring back instead of
/// adding a duplicate. ↓ picks one and Return restores it; without ↓, Return adds the new task as usual.
struct RestoreSuggestions: View {
    let tasks: [TaskItem]
    let highlighted: Int?
    let onPick: (TaskItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("In your archive")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.bottom, 2)
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                Button { onPick(task) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward").imageScale(.small).foregroundStyle(.secondary)
                        Text(task.title).lineLimit(1)
                        Spacer(minLength: 16)
                        if let date = task.archivedAt {
                            Text(date.formatted(.dateTime.month(.abbreviated).day()))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .background(index == highlighted ? Color.accentColor.opacity(0.18) : .clear,
                                in: RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain)
                .help("Bring \u{201C}\(task.title)\u{201D} back to your list, open")
                .accessibilityLabel("Restore \(task.title)")
                .accessibilityAddTraits(index == highlighted ? .isSelected : [])
            }
            Text(highlighted == nil ? "↓ then Return to bring one back · Return adds a new task"
                                    : "Return to bring it back · Esc to close")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 8)
                .padding(.top, 4)
        }
        .font(.callout)
        .padding(5)
        .frame(minWidth: 220, maxWidth: 300, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.cardStroke))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Archived tasks you could bring back")
    }
}
