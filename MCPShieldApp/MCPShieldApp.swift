import MCPShieldCore
import SwiftUI

@main
struct MCPShieldApp: App {
    @StateObject private var model = ScanViewModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup("Tollgate", id: "main") {
            RootView()
                .environmentObject(model)
                .task {
                    await model.scan()
                    #if DEBUG
                    if UserDefaults.standard.bool(forKey: "showAbout") { openWindow(id: "about") }
                    #endif
                }
        }
        .defaultSize(width: 1040, height: 680)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Tollgate") { openWindow(id: "about") }
            }
            CommandGroup(replacing: .newItem) {
                Button("Add Config…") { model.addConfig() }
                    .keyboardShortcut("o")
                Button("Rescan") { Task { await model.scan() } }
                    .keyboardShortcut("r")
                Divider()
                Button("Export JSON…") { model.exportJSON() }
                    .keyboardShortcut("e")
                    .disabled(model.results.isEmpty)
            }
        }

        Window("About Tollgate", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
    }
}

struct RootView: View {
    @EnvironmentObject private var model: ScanViewModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 240, ideal: 270, max: 360)
        } detail: {
            if let result = model.selected {
                ServerDetailView(result: result)
            } else if model.isScanning {
                ProgressView("Scanning…")
            } else if model.results.isEmpty {
                EmptyStateView()
            } else {
                ContentUnavailableView("Select a server", systemImage: "sidebar.left")
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button { model.addConfig() } label: { Label("Add Config", systemImage: "plus") }
                    .help("Add a config file or project folder")
                Button { Task { await model.scan() } } label: { Label("Rescan", systemImage: "arrow.clockwise") }
                    .help("Scan all configs again")
                    .disabled(model.isScanning)
                Button { model.exportJSON() } label: { Label("Export JSON", systemImage: "square.and.arrow.up") }
                    .help("Save a JSON report (secrets are redacted)")
                    .disabled(model.results.isEmpty)
            }
        }
        .alert("Export failed", isPresented: Binding(get: { model.errorMessage != nil },
                                                     set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}

struct EmptyStateView: View {
    @EnvironmentObject private var model: ScanViewModel

    var body: some View {
        ContentUnavailableView {
            Label("No MCP servers found", systemImage: "checkmark.shield")
        } description: {
            Text("Tollgate looked in Claude Desktop, Cursor and Claude Code. If your servers are set up somewhere else, add that config file or project folder.")
        } actions: {
            Button("Add Config…") { model.addConfig() }
                .buttonStyle(.borderedProminent)
        }
    }
}
