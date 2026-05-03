import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeatureHeader(nav: .dashboard)

                // Disk & Memory rings
                HStack(spacing: 16) {
                    diskCard
                    memoryCard
                }

                // Stats row
                HStack(spacing: 12) {
                    MetricCard(
                        title: "Total Cleaned",
                        value: appState.formattedTotalCleaned,
                        subtitle: appState.lastCleanDate.map { "Last: \(relativeDate($0))" } ?? "Never cleaned",
                        color: .green,
                        icon: "sparkles"
                    )
                    MetricCard(
                        title: "Disk Free",
                        value: appState.diskInfo?.formattedFree ?? "—",
                        subtitle: appState.diskInfo.map {
                            "\(Int($0.freeFraction * 100))% of \($0.formattedTotal)"
                        } ?? "Calculating…",
                        color: diskStatusColor,
                        icon: "internaldrive"
                    )
                    MetricCard(
                        title: "RAM Free",
                        value: appState.memoryInfo?.formattedFree ?? "—",
                        subtitle: appState.memoryInfo.map {
                            "\(Int((1 - $0.usedFraction) * 100))% of \($0.formattedTotal)"
                        } ?? "Calculating…",
                        color: .mint,
                        icon: "memorychip"
                    )
                }

                // Quick actions
                Text("QUICK ACTIONS")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()),
                                    GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach([NavDestination.smartScan, .systemJunk, .largeFiles, .apps,
                             .privacy, .memory, .maintenance], id: \.self) { dest in
                        Button {
                            appState.selectedNav = dest
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(dest.color.opacity(0.12))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: dest.icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(dest.color)
                                }
                                Text(dest.label)
                                    .font(.caption.weight(.medium))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(dest.color.opacity(0.1), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Warning banner
                if appState.diskWarning {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Low Disk Space")
                                .font(.subheadline.weight(.semibold))
                            Text("Less than 15% free. Run Smart Scan to reclaim space.")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Scan Now") {
                            appState.selectedNav = .smartScan
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .controlSize(.small)
                    }
                    .padding(14)
                    .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(.orange.opacity(0.2), lineWidth: 1))
                }
            }
            .padding(20)
        }
    }

    // MARK: Disk Card
    private var diskCard: some View {
        VStack(spacing: 12) {
            ZStack {
                if let disk = appState.diskInfo {
                    RingView(fraction: disk.usedFraction, color: diskStatusColor, lineWidth: 14, size: 120)
                    VStack(spacing: 0) {
                        Text("\(Int(disk.usedFraction * 100))%")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text("used").font(.caption2).foregroundStyle(.secondary)
                    }
                } else {
                    ProgressView().frame(width: 120, height: 120)
                }
            }
            Text("Disk Usage")
                .font(.subheadline.weight(.semibold))
            if let disk = appState.diskInfo {
                HStack {
                    dot(.blue); Text(disk.formattedUsed).font(.caption)
                    Spacer()
                    dot(.blue.opacity(0.3)); Text(disk.formattedFree).font(.caption)
                }
                StatusBadge(status: diskBadgeStatus)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Memory Card
    private var memoryCard: some View {
        VStack(spacing: 12) {
            ZStack {
                if let mem = appState.memoryInfo {
                    RingView(fraction: mem.usedFraction, color: .mint, lineWidth: 14, size: 120)
                    VStack(spacing: 0) {
                        Text("\(Int(mem.usedFraction * 100))%")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        Text("used").font(.caption2).foregroundStyle(.secondary)
                    }
                } else {
                    ProgressView().frame(width: 120, height: 120)
                }
            }
            Text("Memory Usage")
                .font(.subheadline.weight(.semibold))
            if let mem = appState.memoryInfo {
                HStack {
                    dot(.mint); Text(mem.formattedUsed).font(.caption)
                    Spacer()
                    dot(.mint.opacity(0.3)); Text(mem.formattedFree).font(.caption)
                }
                StatusBadge(status: mem.usedFraction > 0.85 ? .danger : mem.usedFraction > 0.65 ? .warning : .clean)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func dot(_ color: Color) -> some View {
        Circle().fill(color).frame(width: 8, height: 8)
    }

    private var diskStatusColor: Color {
        guard let f = appState.diskInfo?.freeFraction else { return .blue }
        if f < 0.10 { return .red }
        if f < 0.20 { return .orange }
        return .blue
    }

    private var diskBadgeStatus: StatusBadge.Status {
        guard let f = appState.diskInfo?.freeFraction else { return .clean }
        if f < 0.10 { return .danger }
        if f < 0.20 { return .warning }
        return .clean
    }

    private func relativeDate(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
}
