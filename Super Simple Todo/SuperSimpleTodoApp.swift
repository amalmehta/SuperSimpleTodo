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
                    .keyboardShortcut("1")
                Button("Activity") { NotificationCenter.default.post(name: .showTab, object: "activity") }
                    .keyboardShortcut("2")
                Divider()
            }
            CommandMenu("Tasks") {
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
