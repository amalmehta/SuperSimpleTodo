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

        Settings {
            SettingsView()
        }
    }
}
