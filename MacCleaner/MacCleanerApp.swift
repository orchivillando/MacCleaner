import SwiftUI

@main
struct MacCleanerApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        Window("MacCleaner", id: "main") {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 860, minHeight: 580)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        if appState.diskWarning {
            Label("MacCleaner", systemImage: "exclamationmark.triangle.fill")
        } else if let disk = appState.diskInfo {
            Label("\(Int(disk.freeFraction * 100))% free", systemImage: "sparkle")
        } else {
            Label("MacCleaner", systemImage: "sparkle")
        }
    }
}
