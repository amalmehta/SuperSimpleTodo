import SwiftUI

@main
struct SuperSimpleTodoApp: App {
    @StateObject private var store = TaskStore()

    var body: some Scene {
        Window("Super Simple Todo", id: "main") {
            ContentView()
                .environmentObject(store)
        }
        .defaultSize(width: 420, height: 560)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Task") { NotificationCenter.default.post(name: .newTask, object: nil) }
                    .keyboardShortcut("n")
            }
            CommandGroup(before: .toolbar) {
                Button("Tasks") { NotificationCenter.default.post(name: .showTab, object: "tasks") }
                    .keyboardShortcut("1", modifiers: [.command, .option])
                Button("Calendar") { NotificationCenter.default.post(name: .showTab, object: "calendar") }
                    .keyboardShortcut("2", modifiers: [.command, .option])
                Button("Activity") { NotificationCenter.default.post(name: .showTab, object: "activity") }
                    .keyboardShortcut("3", modifiers: [.command, .option])
                Divider()
            }
            CommandMenu("Tasks") {
                // ⌘1–⌘3 match typing !, !! or !!! after a task.
                ForEach(Priority.allCases.reversed()) { p in
                    Button(p == .none ? "No Priority" : "\(p.name) Priority") {
                        NotificationCenter.default.post(name: .setPriority, object: p)
                    }
                    .keyboardShortcut(KeyEquivalent(Character("\(p.rawValue)")))
                }
                Divider()
                Button("Clear Done") { store.clearDone() }
                    .keyboardShortcut(.delete, modifiers: [.command, .shift])
                    .disabled(store.doneCount == 0)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
}
