import AppKit
import MCPShieldCore
import SwiftUI
import UniformTypeIdentifiers

@MainActor final class ScanViewModel: ObservableObject {
    @Published var results: [ScanResult] = []
    @Published var files: [ConfigDiscovery.FileStatus] = []
    @Published var selection: ScanResult.ID?
    @Published var isScanning = false
    @Published var lastScan: Date?
    @Published var errorMessage: String?
    @Published private(set) var extraURLs: [URL] = []

    private static let extraKey = "extraConfigPaths"

    init() {
        extraURLs = (UserDefaults.standard.stringArray(forKey: Self.extraKey) ?? []).map { URL(fileURLWithPath: $0) }
    }

    var selected: ScanResult? { results.first { $0.id == selection } }

    /// Reads configs off the main thread, then publishes the results.
    func scan() async {
        isScanning = true
        let extra = extraURLs
        let (results, files) = await Task.detached(priority: .userInitiated) {
            let d = ConfigDiscovery.discover(extra: extra)
            return (Scanner.scan(d.servers), d.files)
        }.value
        self.results = results.sorted { ($0.score, $0.server.name) < ($1.score, $1.server.name) }
        self.files = files
        if selection == nil || !results.contains(where: { $0.id == selection }) { selection = self.results.first?.id }
        #if DEBUG
        // For README screenshots: `open Tollgate.app --args -selectServer <name>`
        if let name = UserDefaults.standard.string(forKey: "selectServer"),
           let match = self.results.first(where: { $0.server.name == name }) { selection = match.id }
        #endif
        lastScan = Date()
        isScanning = false
    }

    /// "Add a config file..." lets the user pick any file or folder.
    func addConfig() {
        let panel = NSOpenPanel()
        panel.title = "Add an MCP config file or project folder"
        panel.message = "Pick a config file (for example .mcp.json) or a project folder that contains one."
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.showsHiddenFiles = true
        guard panel.runModal() == .OK else { return }
        let added = panel.urls.filter { !extraURLs.contains($0) }
        guard !added.isEmpty else { return }
        extraURLs += added
        saveExtras()
        Task { await scan() }
    }

    func removeExtra(_ url: URL) {
        extraURLs.removeAll { $0 == url }
        saveExtras()
        Task { await scan() }
    }

    func isExtra(_ path: String) -> Bool {
        extraURLs.contains { path == $0.path || path.hasPrefix($0.path + "/") }
    }

    func extraURL(for path: String) -> URL? {
        extraURLs.first { path == $0.path || path.hasPrefix($0.path + "/") }
    }

    private func saveExtras() {
        UserDefaults.standard.set(extraURLs.map(\.path), forKey: Self.extraKey)
    }

    /// Writes the redacted JSON report wherever the user chooses.
    func exportJSON() {
        let panel = NSSavePanel()
        panel.title = "Export Tollgate report"
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "tollgate-report-\(Date().formatted(.iso8601.year().month().day())).json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try Report.json(for: results).write(to: url, options: .atomic)
        } catch {
            errorMessage = "Could not save the report: \(error.localizedDescription)"
        }
    }

    func revealInFinder(_ path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }
}
