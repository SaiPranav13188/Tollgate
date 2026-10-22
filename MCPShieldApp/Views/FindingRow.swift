import MCPShieldCore
import SwiftUI

struct FindingRow: View {
    let finding: Finding

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SeverityPill(severity: finding.severity)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(finding.ruleID).font(.caption.monospaced()).foregroundStyle(.secondary)
                    Text(finding.title).fontWeight(.semibold)
                }
                HStack(spacing: 8) {
                    Text(finding.target).font(.callout.monospaced())
                    if let evidence = finding.evidence {
                        Text(evidence)
                            .font(.callout.monospaced())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .textSelection(.enabled)
                if !finding.detail.isEmpty {
                    Text(finding.detail).font(.callout).foregroundStyle(.secondary)
                }
                if !finding.fix.isEmpty {
                    (Text("Fix: ").fontWeight(.semibold) + Text(finding.fix))
                        .font(.callout)
                        .textSelection(.enabled)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
    }
}

struct SeverityPill: View {
    let severity: Severity

    private var label: String {
        switch severity {
        case .critical: return "CRIT"
        case .high: return "HIGH"
        case .medium: return "MED"
        case .low: return "LOW"
        case .info: return "INFO"
        }
    }

    var body: some View {
        Text(label)
            .font(.caption2.weight(.bold))
            .foregroundStyle(severity == .medium ? .black : .white)
            .frame(width: 42)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color.forSeverity(severity)))
            .accessibilityLabel("\(severity.rawValue) severity")
    }
}
