import SwiftUI

struct SettingsView: View {
    @AppStorage("hideDoneTasks") private var hideDoneTasks = false

    var body: some View {
        Form {
            Toggle("Hide done tasks", isOn: $hideDoneTasks)
        }
        .padding(20)
        .frame(width: 300)
    }
}
