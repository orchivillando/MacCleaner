import SwiftUI

// MARK: - Maintenance Task Model

struct MaintenanceTask: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    let requiresAdmin: Bool
    var status: TaskStatus = .idle

    enum TaskStatus { case idle, running, done, failed }
}

// MARK: - Maintenance ViewModel

@MainActor
final class MaintenanceViewModel: ObservableObject {
    @Published var tasks: [MaintenanceTask] = [
        MaintenanceTask(id: "dns",      title: "Flush DNS Cache",
                        description: "Clear the DNS resolver cache to fix network issues.",
                        icon: "network", color: .blue, requiresAdmin: false),
        MaintenanceTask(id: "quicklook",title: "Clear QuickLook Cache",
                        description: "Remove cached preview thumbnails to free space.",
                        icon: "eye.slash", color: .cyan, requiresAdmin: false),
        MaintenanceTask(id: "fontcache", title: "Rebuild Font Cache",
                        description: "Remove corrupt font cache files. Requires restart.",
                        icon: "textformat", color: .purple, requiresAdmin: true),
        MaintenanceTask(id: "launchsvc",title: "Rebuild Launch Services",
                        description: "Fix 'Open With' menu and app associations.",
                        icon: "arrow.triangle.2.circlepath", color: .orange, requiresAdmin: false),
        MaintenanceTask(id: "spotlight", title: "Re-index Spotlight",
                        description: "Rebuild Spotlight index for your home folder.",
                        icon: "magnifyingglass", color: .yellow, requiresAdmin: false),
        MaintenanceTask(id: "tmclean",  title: "Clean Time Machine Snapshots",
                        description: "Remove old local Time Machine snapshots.",
                        icon: "clock.arrow.circlepath", color: .green, requiresAdmin: true),
    ]

    func run(id: String) async {
        guard let idx = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[idx].status = .running

        let ok: Bool = await Task.detached(priority: .userInitiated) {
            switch id {
            case "dns":
                return SystemService.run("dscacheutil", args: ["-flushcache"])

            case "quicklook":
                return SystemService.run("qlmanage", args: ["-r", "cache"])

            case "fontcache":
                let cachePath = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent("Library/Caches/com.apple.ATS").path
                return SystemService.runWithAdmin("rm -rf \"\(cachePath)\"")

            case "launchsvc":
                let lsReg = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
                return SystemService.run(lsReg, args: ["-kill", "-r", "-domain", "local", "-domain", "system", "-domain", "user"])

            case "spotlight":
                let home = FileManager.default.homeDirectoryForCurrentUser.path
                return SystemService.run("mdutil", args: ["-E", home])

            case "tmclean":
                return SystemService.runWithAdmin("tmutil deletelocalsnapshots /")

            default:
                return false
            }
        }.value

        tasks[idx].status = ok ? .done : .failed
    }

    func runAll() async {
        for task in tasks {
            await run(id: task.id)
        }
    }
}

// MARK: - Maintenance View

struct MaintenanceView: View {
    @StateObject private var vm = MaintenanceViewModel()
    @State private var isRunningAll = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeatureHeader(nav: .maintenance)

                Button {
                    isRunningAll = true
                    Task {
                        await vm.runAll()
                        isRunningAll = false
                    }
                } label: {
                    if isRunningAll {
                        HStack {
                            ProgressView().controlSize(.small)
                            Text("Running all tasks…")
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                    } else {
                        Label("Run All Tasks", systemImage: "play.fill")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                }
                .buttonStyle(.borderedProminent).tint(.brown)
                .disabled(isRunningAll)

                VStack(spacing: 8) {
                    ForEach($vm.tasks) { $task in
                        MaintenanceTaskRow(task: $task) {
                            Task { await vm.run(id: task.id) }
                        }
                    }
                }

                // Note about admin tasks
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill").foregroundStyle(.secondary).font(.caption)
                    Text("Tasks marked with a lock require administrator password.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(20)
        }
    }
}

// MARK: - Maintenance Task Row

private struct MaintenanceTaskRow: View {
    @Binding var task: MaintenanceTask
    let run: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(task.color.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: task.icon)
                    .foregroundStyle(task.color)
                    .font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(task.title).font(.subheadline.weight(.semibold))
                    if task.requiresAdmin {
                        Image(systemName: "lock.fill")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Text(task.description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }

            Spacer()

            statusView
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var statusView: some View {
        switch task.status {
        case .idle:
            Button("Run", action: run)
                .buttonStyle(.bordered).controlSize(.small)

        case .running:
            ProgressView().controlSize(.small)

        case .done:
            Label("Done", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.medium))
                .foregroundStyle(.green)

        case .failed:
            VStack(spacing: 4) {
                Label("Failed", systemImage: "xmark.circle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.red)
                Button("Retry", action: run)
                    .buttonStyle(.bordered).controlSize(.mini)
            }
        }
    }
}
