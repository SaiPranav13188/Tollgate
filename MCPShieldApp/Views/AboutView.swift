import MCPShieldCore
import SwiftUI

/// About screen with the responsible-use rules (plan section 15).
struct AboutView: View {
    private let rules = [
        "Tollgate reads config files. It never runs, changes or uploads them.",
        "Only scan configs and servers that you own or trust.",
        "Do not point it at other people's systems.",
        "Findings never show full secrets.",
        "If you find a problem in someone's public project, report it privately to the maintainer first.",
        "Everything stays on your Mac. No account, no upload.",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tollgate").font(.title.weight(.semibold))
                    Text("Version \(Report.version)").foregroundStyle(.secondary)
                    Text("Audits the MCP servers set up on this Mac.").font(.callout)
                }
            }
            Divider()
            Text("Responsible use").font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(rules, id: \.self) { rule in
                    Label(rule, systemImage: "checkmark.shield")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Text("Scores are heuristics, measured on a labelled test set. They are not a guarantee of safety.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 460)
    }
}
