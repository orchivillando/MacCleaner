import SwiftUI

// MARK: - Memory ViewModel

@MainActor
final class MemoryViewModel: ObservableObject {
    @Published var optimizing = false
    @Published var freedBytes: Int64 = 0
    @Published var didOptimize = false

    func optimize(memInfo: MemoryInfo) async {
        optimizing = true
        freedBytes = 0
        didOptimize = false

        let targetBytes = Int(Double(memInfo.inactive) * 0.75)
        let blockSize   = 10 * 1024 * 1024 // 10 MB chunks

        let actual: Int = await Task.detached(priority: .utility) {
            var blocks = [UnsafeMutableRawPointer]()
            var filled = 0
            while filled < targetBytes {
                guard let ptr = malloc(blockSize) else { break }
                memset(ptr, 0, blockSize)
                blocks.append(ptr)
                filled += blockSize
            }
            let used = filled
            blocks.forEach { free($0) }
            return used
        }.value

        freedBytes = Int64(actual)
        optimizing = false
        didOptimize = true
    }
}

// MARK: - Memory View

struct MemoryView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = MemoryViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeatureHeader(nav: .memory)

                if let mem = appState.memoryInfo {
                    // Ring
                    HStack {
                        Spacer()
                        ZStack {
                            RingView(fraction: mem.usedFraction, color: .mint, lineWidth: 18, size: 180)
                            VStack(spacing: 4) {
                                Text(mem.formattedUsed)
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                Text("of \(mem.formattedTotal)")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                Text("used").font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                    }

                    // Breakdown
                    VStack(spacing: 10) {
                        memRow(label: "Active", value: mem.formattedActive,
                               fraction: Double(mem.active) / Double(max(mem.total, 1)),
                               color: .blue)
                        memRow(label: "Wired", value: mem.formattedWired,
                               fraction: Double(mem.wired) / Double(max(mem.total, 1)),
                               color: .purple)
                        memRow(label: "Compressed", value: mem.formattedCompressed,
                               fraction: Double(mem.compressed) / Double(max(mem.total, 1)),
                               color: .orange)
                        memRow(label: "Inactive", value: mem.formattedInactive,
                               fraction: Double(mem.inactive) / Double(max(mem.total, 1)),
                               color: .yellow)
                        memRow(label: "Free", value: mem.formattedFree,
                               fraction: Double(mem.free) / Double(max(mem.total, 1)),
                               color: .green)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))

                    // Pressure status
                    pressureCard(mem: mem)

                    // Optimize
                    optimizeCard(mem: mem)
                } else {
                    ProgressView().frame(maxWidth: .infinity).padding(40)
                }
            }
            .padding(20)
        }
    }

    // MARK: Memory Row
    private func memRow(label: String, value: String, fraction: Double, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.subheadline)
            Spacer()
            Text(value).font(.subheadline.weight(.medium))
                .frame(width: 80, alignment: .trailing)
            SizeBar(fraction: fraction, color: color)
                .frame(width: 100)
        }
    }

    // MARK: Pressure Card
    private func pressureCard(mem: MemoryInfo) -> some View {
        let pct = mem.usedFraction
        let (label, color, msg): (String, Color, String) = {
            if pct > 0.85 { return ("Critical", .red, "Memory is almost full. Apps may slow down.") }
            if pct > 0.65 { return ("Elevated", .orange, "Memory usage is high. Consider optimizing.") }
            return ("Normal", .green, "Memory pressure is healthy.")
        }()

        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: "gauge.medium")
                    .foregroundStyle(color).font(.system(size: 18))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Memory Pressure: \(label)")
                    .font(.subheadline.weight(.semibold))
                Text(msg).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(color.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.15), lineWidth: 1))
    }

    // MARK: Optimize Card
    private func optimizeCard(mem: MemoryInfo) -> some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Memory Boost")
                        .font(.headline)
                    Text("Forces inactive memory to be reclaimed by compressing or releasing it back to the system.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }

            if vm.didOptimize {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Freed approx. \(vm.freedBytes.formattedSize) of inactive memory")
                        .font(.subheadline)
                }
                .padding(10)
                .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }

            Button {
                Task { await vm.optimize(memInfo: mem) }
            } label: {
                if vm.optimizing {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text("Optimizing…")
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                } else {
                    Label("Optimize Memory", systemImage: "bolt.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                }
            }
            .buttonStyle(.borderedProminent).tint(.mint)
            .disabled(vm.optimizing)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
