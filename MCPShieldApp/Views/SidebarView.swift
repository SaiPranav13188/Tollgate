import MCPShieldCore
import SwiftUI

/// List of servers with their scores, plus the config files that were checked.
struct SidebarView: View {
    @EnvironmentObject private var model: ScanViewModel

    var body: some View {
        List(selection: $model.selection) {
            Section("Servers") {
                ForEach(model.results) { result in
                    ServerRow(result: result).tag(result.id)
                }
                if model.results.isEmpty && !model.isScanning {
                    Text("None found").foregroundStyle(.secondary)
                }
            }

            Section("Config files") {
                ForEach(model.files) { file in
                    ConfigFileRow(file: file)
                        .contextMenu {
                            if let url = model.extraURL(for: file.path) {
                                Button("Remove from Tollgate") { model.removeExtra(url) }
                            }
                            if case .missing = file.state {} else {
                                Button("Show in Finder") { model.revealInFinder(file.path) }
                            }
                        }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button { model.addConfig() } label: { Label("Add Config…", systemImage: "plus") }
                    Spacer()
                    Button { Task { await model.scan() } } label: { Label("Rescan", systemImage: "arrow.clockwise") }
                        .disabled(model.isScanning)
                }
                .buttonStyle(.borderless)
                if let last = model.lastScan {
                    Text("Scanned \(last.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(.bar)
        }
    }
}

struct ServerRow: View {
    let result: ScanResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(result.server.name).fontWeight(.medium)
                Text(result.server.source).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            ScoreBadge(score: result.score)
        }
        .padding(.vertical, 2)
    }
}

struct ScoreBadge: View {
    let score: Int

    var body: some View {
        Text("\(score)")
            .font(.callout.monospacedDigit().weight(.semibold))
            .foregroundStyle(.white)
            .frame(minWidth: 34)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.forScore(score)))
            .accessibilityLabel("Score \(score), \(Scoring.grade(score))")
    }
}

struct ConfigFileRow: View {
    let file: ConfigDiscovery.FileStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(file.label).font(.callout)
            Text(file.note)
                .font(.caption)
                .foregroundStyle(isProblem ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
        }
        .help(file.path)
        .selectionDisabled()
    }

    private var isProblem: Bool {
        switch file.state {
        case .unreadable, .invalidJSON: return true
        default: return false
        }
    }
}

extension Color {
    static func forScore(_ s: Int) -> Color { s >= 85 ? .green : s >= 60 ? .orange : .red }

    static func forSeverity(_ s: Severity) -> Color {
        switch s {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        case .info: return .gray
        }
    }
}
