import SwiftUI

// MARK: - System Junk ViewModel

@MainActor
final class SystemJunkViewModel: ObservableObject {
    @Published var scanning = false
    @Published var cleaning = false
    @Published var categoryResults: [String: [JunkItem]] = [:]
    @Published var selectedIDs: Set<UUID> = []
    @Published var progress: Double = 0
    @Published var scanned = false

    var totalSelected: Int64 {
        categoryResults.values.flatMap { $0 }
            .filter { selectedIDs.contains($0.id) }
            .map(\.size).reduce(0, +)
    }

    var totalFound: Int64 {
        categoryResults.values.flatMap { $0 }.map(\.size).reduce(0, +)
    }

    func scan() async {
        scanning = true
        scanned = false
        categoryResults = [:]
        selectedIDs = []
        progress = 0
        let cats = JunkCategory.all
        for (i, cat) in cats.enumerated() {
            let items = await ScanServices.scanJunk(cat)
            categoryResults[cat.id] = items
            items.forEach { selectedIDs.insert($0.id) }
            progress = Double(i + 1) / Double(cats.count)
        }
        scanning = false
        scanned = true
    }

    func clean(appState: AppState) async {
        cleaning = true
        let urls = categoryResults.values.flatMap { $0 }
            .filter { selectedIDs.contains($0.id) }
            .map(\.url)
        let freed = await ScanServices.deleteItems(urls)
        appState.recordCleaned(freed)
        for key in categoryResults.keys {
            categoryResults[key] = categoryResults[key]?.filter { !selectedIDs.contains($0.id) }
        }
        selectedIDs = []
        cleaning = false
    }
}

// MARK: - System Junk View

struct SystemJunkView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = SystemJunkViewModel()
    @State private var expandedCat: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeatureHeader(nav: .systemJunk)

                if !vm.scanned && !vm.scanning {
                    // Splash
                    VStack(spacing: 16) {
                        ForEach(JunkCategory.all) { cat in
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(cat.color.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: cat.icon)
                                        .foregroundStyle(cat.color)
                                        .font(.system(size: 14))
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(cat.label).font(.subheadline.weight(.medium))
                                    Text(cat.description).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                        }

                        Button {
                            Task { await vm.scan() }
                        } label: {
                            Label("Scan System Junk", systemImage: "magnifyingglass")
                                .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange).controlSize(.large)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                } else if vm.scanning {
                    scanningView
                } else {
                    resultsView
                }
            }
            .padding(20)
        }
    }

    // MARK: Scanning
    private var scanningView: some View {
        VStack(spacing: 20) {
            ProgressView(value: vm.progress)
                .progressViewStyle(.linear)
                .tint(.orange)
            Text("Scanning… \(Int(vm.progress * 100))%")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Results
    private var resultsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Banner
            HStack {
                VStack(alignment: .leading) {
                    Text(vm.totalFound.formattedSize)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("Found across \(JunkCategory.all.count) categories")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await vm.scan() }
                } label: {
                    Label("Re-Scan", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered).controlSize(.small)
            }
            .padding(14)
            .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            // Category rows
            ForEach(JunkCategory.all) { cat in
                let items = vm.categoryResults[cat.id] ?? []
                JunkCategoryRow(
                    category: cat,
                    items: items,
                    selectedIDs: $vm.selectedIDs,
                    isExpanded: Binding(
                        get: { expandedCat == cat.id },
                        set: { expandedCat = $0 ? cat.id : nil }
                    )
                )
            }

            // Clean button
            if vm.totalFound > 0 {
                Button {
                    Task { await vm.clean(appState: appState) }
                } label: {
                    if vm.cleaning {
                        ProgressView().controlSize(.small)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                    } else {
                        Label("Clean \(vm.totalSelected.formattedSize)", systemImage: "trash.fill")
                            .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(vm.selectedIDs.isEmpty || vm.cleaning)
            }
        }
    }
}

// MARK: - Junk Category Row

private struct JunkCategoryRow: View {
    let category: JunkCategory
    let items: [JunkItem]
    @Binding var selectedIDs: Set<UUID>
    @Binding var isExpanded: Bool

    private var allSelected: Bool { items.allSatisfy { selectedIDs.contains($0.id) } }
    private var totalSize: Int64 { items.map(\.size).reduce(0, +) }

    var body: some View {
        VStack(spacing: 0) {
            Button { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } } label: {
                HStack(spacing: 10) {
                    if !items.isEmpty {
                        Toggle("", isOn: Binding(
                            get: { allSelected },
                            set: { on in
                                if on { items.forEach { selectedIDs.insert($0.id) } }
                                else  { items.forEach { selectedIDs.remove($0.id) } }
                            }
                        ))
                        .toggleStyle(.checkbox).labelsHidden()
                    }
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(category.color.opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: category.icon)
                            .foregroundStyle(category.color)
                            .font(.system(size: 12))
                    }
                    Text(category.label).font(.subheadline.weight(.semibold))
                    Spacer()
                    if items.isEmpty {
                        Text("Clean").font(.caption.weight(.medium)).foregroundStyle(.green)
                    } else {
                        Text(totalSize.formattedSize)
                            .font(.caption.weight(.bold)).foregroundStyle(category.color)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded && !items.isEmpty {
                Divider()
                ForEach(items.prefix(15)) { item in
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { selectedIDs.contains(item.id) },
                            set: { if $0 { selectedIDs.insert(item.id) } else { selectedIDs.remove(item.id) } }
                        ))
                        .toggleStyle(.checkbox).labelsHidden()
                        Text(item.url.lastPathComponent).font(.caption).lineLimit(1)
                        Spacer()
                        Text(item.size.formattedSize).font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 4)
                }
                if items.count > 15 {
                    Text("+ \(items.count - 15) more files")
                        .font(.caption2).foregroundStyle(.tertiary)
                        .padding(.horizontal, 20).padding(.bottom, 8)
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
