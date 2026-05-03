import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkle")
                    .foregroundStyle(.purple)
                Text("MacCleaner")
                    .font(.headline)
                Spacer()
                Button {
                    openWindow(id: "main")
                } label: {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)

            Divider()

            // Disk
            if let disk = appState.diskInfo {
                HStack(spacing: 12) {
                    ZStack {
                        RingView(fraction: disk.usedFraction,
                                 color: diskColor(disk.freeFraction),
                                 lineWidth: 6, size: 44)
                        Text("\(Int(disk.usedFraction * 100))%")
                            .font(.system(size: 9, weight: .bold))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Disk — \(disk.formattedFree) free")
                            .font(.subheadline.weight(.medium))
                        SizeBar(fraction: disk.usedFraction,
                                color: diskColor(disk.freeFraction))
                        Text("\(disk.formattedUsed) used of \(disk.formattedTotal)")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }

            // Memory
            if let mem = appState.memoryInfo {
                HStack(spacing: 12) {
                    ZStack {
                        RingView(fraction: mem.usedFraction, color: .mint, lineWidth: 6, size: 44)
                        Text("\(Int(mem.usedFraction * 100))%")
                            .font(.system(size: 9, weight: .bold))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Memory — \(mem.formattedFree) free")
                            .font(.subheadline.weight(.medium))
                        SizeBar(fraction: mem.usedFraction, color: .mint)
                        Text("\(mem.formattedUsed) used of \(mem.formattedTotal)")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }

            Divider()

            // Quick Actions
            VStack(spacing: 2) {
                quickBtn(label: "Smart Scan", icon: "sparkle.magnifyingglass", dest: .smartScan)
                quickBtn(label: "System Junk", icon: "trash.fill", dest: .systemJunk)
                quickBtn(label: "Memory Boost", icon: "memorychip", dest: .memory)
            }
            .padding(.vertical, 6)

            Divider()

            // Total cleaned
            HStack {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green).font(.caption)
                Text("Total cleaned: \(appState.formattedTotalCleaned)")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
        }
        .frame(width: 280)
    }

    @ViewBuilder
    private func quickBtn(label: String, icon: String, dest: NavDestination) -> some View {
        Button {
            appState.selectedNav = dest
            openWindow(id: "main")
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(dest.color)
                    .frame(width: 20)
                Text(label)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func diskColor(_ freeF: Double) -> Color {
        if freeF < 0.10 { return .red }
        if freeF < 0.20 { return .orange }
        return .blue
    }
}
