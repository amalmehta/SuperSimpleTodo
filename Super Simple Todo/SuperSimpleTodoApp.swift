import SwiftUI

@main
struct SuperSimpleTodoApp: App {
    @StateObject private var store = TaskStore()

    var body: some Scene {
        Window("Super Simple Todo", id: "main") {
            ContentView()
                .environmentObject(store)
        }
        .defaultSize(width: 380, height: 480)

        Settings {
            SettingsView()
        }
    }
}
