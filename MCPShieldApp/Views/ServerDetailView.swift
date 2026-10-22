import MCPShieldCore
import SwiftUI

/// Score card and findings for one server.
struct ServerDetailView: View {
    @EnvironmentObject private var model: ScanViewModel
    let result: ScanResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                ScoreCard(result: result)
                findings
                HStack {
                    Spacer()
                    Button { model.exportJSON() } label: { Label("Export JSON…", systemImage: "square.and.arrow.up") }
                }
            }
            .padding(24)
            .frame(maxWidth: 820, alignment: .leading)
        }
        .navigationTitle(result.server.name)
        .navigationSubtitle(result.server.source)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(result.server.name).font(.largeTitle.weight(.semibold))
            HStack(spacing: 6) {
                Text(result.server.source)
                Text("·")
                Button(result.server.sourcePath) { model.revealInFinder(result.server.sourcePath) }
                    .buttonStyle(.link)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help("Show in Finder")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
            Text(result.server.redactedCommandLine)
                .font(.callout.monospaced())
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.5)))
        }
    }

    @ViewBuilder private var findings: some View {
        Text("Findings (\(result.findings.count))").font(.title3.weight(.semibold))
        if result.findings.isEmpty {
            Label("No problems found in this config.", systemImage: "checkmark.seal.fill")
                .foregroundStyle(.green)
                .padding(.vertical, 8)
        } else {
            VStack(spacing: 0) {
                ForEach(result.findings) { finding in
                    FindingRow(finding: finding)
                    if finding.id != result.findings.last?.id { Divider() }
                }
            }
            .background(RoundedRectangle(cornerRadius: 10).fill(.background.secondary))
        }
    }
}

struct ScoreCard: View {
    let result: ScanResult

    /// v1 only checks config and secrets; tools and privacy need v1.5.
    static let checkedInV1: Set<MCPShieldCore.Category> = [.config, .secrets]

    var body: some View {
        HStack(alignment: .center, spacing: 28) {
            Gauge(value: Double(result.score), in: 0...100) {
                EmptyView()
            } currentValueLabel: {
                Text("\(result.score)").font(.title.monospacedDigit().weight(.bold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(Color.forScore(result.score))
            .scaleEffect(1.5)
            .frame(width: 90, height: 90)

            VStack(alignment: .leading, spacing: 10) {
                Text(Scoring.grade(result.score))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.forScore(result.score))
                HStack(spacing: 18) {
                    ForEach(MCPShieldCore.Category.allCases, id: \.self) { c in
                        CategoryScore(name: c.rawValue.capitalized,
                                      value: Self.checkedInV1.contains(c) ? result.categoryScores[c.rawValue] : nil)
                    }
                }
            }
            Spacer()
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 12).fill(.background.secondary))
    }
}

struct CategoryScore: View {
    let name: String
    let value: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.caption).foregroundStyle(.secondary)
            Text(value.map(String.init) ?? "--")
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(value.map { Color.forScore($0) } ?? .secondary)
            ProgressView(value: Double(value ?? 0), total: 100)
                .tint(value.map { Color.forScore($0) } ?? .secondary)
                .frame(width: 70)
        }
        .help(value == nil ? "Not checked in this version" : "\(name): \(value!)/100")
    }
}
