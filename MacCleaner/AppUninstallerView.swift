import SwiftUI

// MARK: - App Uninstaller ViewModel

@MainActor
final class AppUninstallerViewModel: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var scanning = false
    @Published var scanned = false
    @Published var selectedApp: AppInfo? = nil
    @Published var selectedLeftovers: Set<UUID> = []
    @Published var uninstalling = false
    @Published var searchText = ""

    var filtered: [AppInfo] {
        if searchText.isEmpty { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func scan() async {
        scanning = true
        apps = await ScanServices.scanApps()
        scanned = true
        scanning = false
    }

    func selectApp(_ app: AppInfo) {
        selectedApp = app
        selectedLeftovers = Set(app.leftovers.map(\.id))
    }

    func uninstall(appState: AppState) async {
        guard let app = selectedApp else { return }
        uninstalling = true
        var urls = [app.url]
        urls += app.leftovers.filter { selectedLeftovers.contains($0.id) }.map(\.url)
        let freed = await ScanServices.deleteItems(urls)
        appState.recordCleaned(freed)
        apps.removeAll { $0.id == app.id }
        selectedApp = nil
        selectedLeftovers = []
        uninstalling = false
    }
}

// MARK: - App Uninstaller View

struct AppUninstallerView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = AppUninstallerViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FeatureHeader(nav: .apps)

                    if !vm.scanned && !vm.scanning {
                        splashView
                    } else if vm.scanning {
                        scanningView
                    } else {
                        appsContent
                    }
                }
                .padding(20)
            }
        }
    }

    // MARK: Splash
    private var splashView: some View {
        VStack(spacing: 16) {
            Image(systemName: "app.badge.minus").font(.system(size: 56)).foregroundStyle(.red.opacity(0.7))
            Text("Uninstall apps & remove leftovers").font(.title3.weight(.semibold))
            Text("Finds app bundles in /Applications and ~/Applications, and detects leftover files in Library folders.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button { Task { await vm.scan() } } label: {
                Label("Scan Applications", systemImage: "magnifyingglass")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent).tint(.red).controlSize(.large)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Scanning
    private var scanningView: some View {
        VStack(spacing: 12) {
            ProgressView().scaleEffect(1.5)
            Text("Scanning applications…").font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(40)
    }

    // MARK: Apps Content
    private var appsContent: some View {
        HStack(alignment: .top, spacing: 16) {
            // App list
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search apps…", text: $vm.searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))

                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(vm.filtered) { app in
                            AppListRow(app: app, isSelected: vm.selectedApp?.id == app.id) {
                                vm.selectApp(app)
                            }
                        }
                    }
                }
            }
            .frame(width: 220)

            // Detail panel
            if let app = vm.selectedApp {
                appDetail(app)
            } else {
                EmptyStateView(
                    icon: "app.badge",
                    title: "Select an app",
                    message: "Choose an app from the list to see details and leftovers."
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: App Detail
    @ViewBuilder
    private func appDetail(_ app: AppInfo) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // App header
            HStack(spacing: 14) {
                Image(nsImage: app.icon)
                    .resizable().scaledToFit()
                    .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text(app.name).font(.headline)
                    Text(app.bundleID ?? "Unknown bundle ID")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(app.appSize.formattedSize + " app")
                        .font(.caption.weight(.medium)).foregroundStyle(.red)
                }
                Spacer()
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            // Leftovers
            if app.leftovers.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("No leftovers found").font(.subheadline)
                }
                .padding(12)
                .background(.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("LEFTOVERS")
                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)

                    ForEach(app.leftovers) { leftover in
                        HStack {
                            Toggle("", isOn: Binding(
                                get: { vm.selectedLeftovers.contains(leftover.id) },
                                set: {
                                    if $0 { vm.selectedLeftovers.insert(leftover.id) }
                                    else  { vm.selectedLeftovers.remove(leftover.id) }
                                }
                            ))
                            .toggleStyle(.checkbox).labelsHidden()
                            Image(systemName: "doc").foregroundStyle(.secondary).font(.caption)
                            Text(leftover.url.lastPathComponent).font(.caption).lineLimit(1)
                            Spacer()
                            Text(leftover.size.formattedSize)
                                .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 3)
                    }
                }
                .padding(12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }

            // Size summary
            let leftoverSize = app.leftovers
                .filter { vm.selectedLeftovers.contains($0.id) }
                .map(\.size).reduce(0, +)
            let totalRemove = app.appSize + leftoverSize
            HStack {
                Text("Will free:")
                    .font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text(totalRemove.formattedSize)
                    .font(.title3.weight(.bold)).foregroundStyle(.red)
            }

            // Uninstall button
            Button {
                Task { await vm.uninstall(appState: appState) }
            } label: {
                if vm.uninstalling {
                    ProgressView().controlSize(.small)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                } else {
                    Label("Uninstall \(app.name)", systemImage: "trash.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 10)
                }
            }
            .buttonStyle(.borderedProminent).tint(.red)
            .disabled(vm.uninstalling)

            Text("Files will be moved to Trash. You can recover them if needed.")
                .font(.caption2).foregroundStyle(.tertiary).multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - App List Row

private struct AppListRow: View {
    let app: AppInfo
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(nsImage: app.icon).resizable().scaledToFit().frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text(app.name).font(.subheadline.weight(.medium)).lineLimit(1)
                    Text(app.totalSize.formattedSize).font(.caption2).foregroundStyle(.secondary)
                    if !app.leftovers.isEmpty {
                        Text("\(app.leftovers.count) leftover(s)")
                            .font(.caption2).foregroundStyle(.orange)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
