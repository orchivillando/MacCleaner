import SwiftUI

// MARK: - Privacy ViewModel

@MainActor
final class PrivacyViewModel: ObservableObject {
    @Published var groups: [PrivacyGroup] = []
    @Published var scanning = false
    @Published var scanned = false
    @Published var selectedIDs: Set<UUID> = []
    @Published var cleaning = false

    var totalSelected: Int64 {
        groups.flatMap(\.items).filter { selectedIDs.contains($0.id) }.map(\.size).reduce(0, +)
    }

    func scan() async {
        scanning = true
        groups = await ScanServices.scanPrivacy()
        groups.flatMap(\.items).forEach { selectedIDs.insert($0.id) }
        scanned = true
        scanning = false
    }

    func clean(appState: AppState) async {
        cleaning = true
        let urls = groups.flatMap(\.items).filter { selectedIDs.contains($0.id) }.map(\.url)
        let freed = await ScanServices.deleteItems(urls, permanent: true)
        appState.recordCleaned(freed)
        for i in groups.indices {
            groups[i].items.removeAll { selectedIDs.contains($0.id) }
        }
        selectedIDs = []
        cleaning = false
    }
}

// MARK: - Privacy View

struct PrivacyView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = PrivacyViewModel()
    @State private var showWarning = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeatureHeader(nav: .privacy)

                if !vm.scanned && !vm.scanning {
                    splashView
                } else if vm.scanning {
                    scanningView
                } else {
                    resultsView
                }
            }
            .padding(20)
        }
        .confirmationDialog("Are you sure?", isPresented: $showWarning, titleVisibility: .visible) {
            Button("Delete Permanently", role: .destructive) {
                Task { await vm.clean(appState: appState) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Privacy files will be permanently deleted and cannot be recovered from Trash.")
        }
    }

    // MARK: Splash
    private var splashView: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill").font(.system(size: 56)).foregroundStyle(.green.opacity(0.8))
            Text("Clean browser & system history").font(.title3.weight(.semibold))
            VStack(alignment: .leading, spacing: 8) {
                ForEach(BrowserType.allCases, id: \.self) { browser in
                    HStack {
                        Image(systemName: browser.icon).foregroundStyle(browser.color).frame(width: 20)
                        Text(browser.label).font(.subheadline)
                    }
                }
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button { Task { await vm.scan() } } label: {
                Label("Scan Privacy Data", systemImage: "magnifyingglass")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent).tint(.green).controlSize(.large)
        }
        .padding(20).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Scanning
    private var scanningView: some View {
        VStack(spacing: 12) {
            ProgressView().scaleEffect(1.5)
            Text("Scanning privacy data…").font(.subheadline).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity).padding(40)
    }

    // MARK: Results
    @ViewBuilder
    private var resultsView: some View {
        let hasItems = vm.groups.flatMap(\.items).count > 0

        if !hasItems {
            EmptyStateView(icon: "lock.shield.fill", title: "Privacy is clean",
                           message: "No browsing history or cached data found.")
        } else {
            VStack(alignment: .leading, spacing: 14) {
                // Warning banner
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.shield.fill").foregroundStyle(.orange)
                    Text("These files will be permanently deleted — not moved to Trash.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

                ForEach(vm.groups) { group in
                    PrivacyGroupCard(group: group, selectedIDs: $vm.selectedIDs)
                }

                Button { showWarning = true } label: {
                    if vm.cleaning {
                        ProgressView().controlSize(.small)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                    } else {
                        Label("Delete \(vm.totalSelected.formattedSize)", systemImage: "lock.shield.fill")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                }
                .buttonStyle(.borderedProminent).tint(.green)
                .disabled(vm.selectedIDs.isEmpty || vm.cleaning)
            }
        }
    }
}

// MARK: - Privacy Group Card

private struct PrivacyGroupCard: View {
    let group: PrivacyGroup
    @Binding var selectedIDs: Set<UUID>
    @State private var expanded = true

    private var totalSize: Int64 { group.items.map(\.size).reduce(0, +) }
    private var allSelected: Bool { group.items.allSatisfy { selectedIDs.contains($0.id) } }

    var body: some View {
        VStack(spacing: 0) {
            Button { withAnimation { expanded.toggle() } } label: {
                HStack(spacing: 10) {
                    if !group.items.isEmpty {
                        Toggle("", isOn: Binding(
                            get: { allSelected },
                            set: { on in
                                if on { group.items.forEach { selectedIDs.insert($0.id) } }
                                else  { group.items.forEach { selectedIDs.remove($0.id) } }
                            }
                        )).toggleStyle(.checkbox).labelsHidden()
                    }
                    Image(systemName: group.browser.icon)
                        .foregroundStyle(group.browser.color).frame(width: 20)
                    Text(group.browser.label).font(.subheadline.weight(.semibold))
                    Spacer()
                    if group.items.isEmpty {
                        Text("Clean").font(.caption).foregroundStyle(.green)
                    } else {
                        Text(totalSize.formattedSize)
                            .font(.caption.weight(.bold)).foregroundStyle(group.browser.color)
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 10).contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded && !group.items.isEmpty {
                Divider()
                ForEach(group.items) { item in
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { selectedIDs.contains(item.id) },
                            set: { if $0 { selectedIDs.insert(item.id) } else { selectedIDs.remove(item.id) } }
                        )).toggleStyle(.checkbox).labelsHidden()
                        Text(item.label).font(.subheadline)
                        Spacer()
                        Text(item.size.formattedSize).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 6)
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
