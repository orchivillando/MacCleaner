import SwiftUI

// MARK: - Smart Scan ViewModel

@MainActor
final class SmartScanViewModel: ObservableObject {
    enum Phase { case idle, scanning, done }

    @Published var phase: Phase = .idle
    @Published var results: [(JunkCategory, [JunkItem])] = []
    @Published var progress: Double = 0
    @Published var currentCategory: String = ""
    @Published var selectedIDs: Set<UUID> = []
    @Published var isCleaning = false

    private let categories = JunkCategory.all

    var totalSize: Int64 {
        results.flatMap(\.1)
            .filter { selectedIDs.contains($0.id) }
            .map(\.size)
            .reduce(0, +)
    }

    var totalFound: Int64 {
        results.flatMap(\.1).map(\.size).reduce(0, +)
    }

    func startScan() async {
        phase = .scanning
        results = []
        selectedIDs = []
        progress = 0

        for (idx, cat) in categories.enumerated() {
            currentCategory = cat.label
            let items = await ScanServices.scanJunk(cat)
            results.append((cat, items))
            items.forEach { selectedIDs.insert($0.id) }
            progress = Double(idx + 1) / Double(categories.count)
        }
        phase = .done
    }

    func clean(recordIn appState: AppState) async {
        isCleaning = true
        let urls = results.flatMap(\.1)
            .filter { selectedIDs.contains($0.id) }
            .map(\.url)
        let freed = await ScanServices.deleteItems(urls)
        appState.recordCleaned(freed)
        // Remove cleaned items from results
        results = results.map { (cat, items) in
            (cat, items.filter { !selectedIDs.contains($0.id) })
        }
        selectedIDs = []
        isCleaning = false
    }
}

// MARK: - Smart Scan View

struct SmartScanView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = SmartScanViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FeatureHeader(nav: .smartScan)

                switch vm.phase {
                case .idle:    idleContent
                case .scanning: scanningContent
                case .done:    resultsContent
                }
            }
            .padding(20)
        }
        .toolbar {
            if vm.phase == .done {
                ToolbarItem(placement: .automatic) {
                    Button("Re-Scan") { Task { await vm.startScan() } }
                }
            }
        }
    }

    // MARK: Idle
    private var idleContent: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(.purple.opacity(0.08))
                    .frame(width: 160, height: 160)
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple)
            }
            .frame(maxWidth: .infinity)

            Text("Scan all categories at once")
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                ForEach(JunkCategory.all) { cat in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.purple.opacity(0.7))
                        Text(cat.label)
                            .font(.subheadline)
                        Spacer()
                        Text(cat.description)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            Button {
                Task { await vm.startScan() }
            } label: {
                Label("Start Smart Scan", systemImage: "sparkle.magnifyingglass")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .controlSize(.large)
        }
    }

    // MARK: Scanning
    private var scanningContent: some View {
        VStack(spacing: 24) {
            ZStack {
                RingView(fraction: vm.progress, color: .purple, lineWidth: 16, size: 150)
                VStack(spacing: 4) {
                    Text("\(Int(vm.progress * 100))%")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("Scanning…")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)

            Text(vm.currentCategory)
                .font(.subheadline).foregroundStyle(.secondary)
                .animation(.easeInOut, value: vm.currentCategory)

            VStack(spacing: 6) {
                ForEach(JunkCategory.all) { cat in
                    let done = vm.results.contains(where: { $0.0.id == cat.id })
                    HStack {
                        Image(systemName: done ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(done ? .green : .secondary)
                        Text(cat.label).font(.subheadline)
                        Spacer()
                        if done, let res = vm.results.first(where: { $0.0.id == cat.id }) {
                            Text(res.1.map(\.size).reduce(0, +).formattedSize)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: Results
    private var resultsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Summary banner
            HStack {
                VStack(alignment: .leading) {
                    Text(vm.totalFound.formattedSize)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.purple)
                    Text("Found in \(vm.results.filter { !$0.1.isEmpty }.count) categories")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(vm.totalSize.formattedSize)
                        .font(.title2.weight(.semibold))
                    Text("Selected to clean")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

            // Category rows
            ForEach(vm.results.filter { !$0.1.isEmpty }, id: \.0.id) { (cat, items) in
                CategoryResultRow(category: cat, items: items, selectedIDs: $vm.selectedIDs)
            }

            if vm.results.allSatisfy({ $0.1.isEmpty }) {
                EmptyStateView(
                    icon: "checkmark.seal.fill",
                    title: "Your Mac is clean!",
                    message: "No junk files found."
                )
            } else {
                // Clean button
                Button {
                    Task { await vm.clean(recordIn: appState) }
                } label: {
                    if vm.isCleaning {
                        ProgressView().controlSize(.small)
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                    } else {
                        Label("Clean \(vm.totalSize.formattedSize)", systemImage: "trash.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(vm.selectedIDs.isEmpty || vm.isCleaning)
            }
        }
    }
}

// MARK: - Category Result Row

private struct CategoryResultRow: View {
    let category: JunkCategory
    let items: [JunkItem]
    @Binding var selectedIDs: Set<UUID>
    @State private var expanded = false

    private var categorySelected: Bool {
        items.allSatisfy { selectedIDs.contains($0.id) }
    }
    private var totalSize: Int64 { items.map(\.size).reduce(0, +) }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            } label: {
                HStack {
                    Toggle("", isOn: Binding(
                        get: { categorySelected },
                        set: { on in
                            if on { items.forEach { selectedIDs.insert($0.id) } }
                            else  { items.forEach { selectedIDs.remove($0.id) } }
                        }
                    ))
                    .toggleStyle(.checkbox)
                    .labelsHidden()

                    Image(systemName: category.icon)
                        .foregroundStyle(category.color)
                        .frame(width: 20)

                    Text(category.label)
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Text(totalSize.formattedSize)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(category.color)

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                Divider()
                ForEach(items.prefix(20)) { item in
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { selectedIDs.contains(item.id) },
                            set: { if $0 { selectedIDs.insert(item.id) } else { selectedIDs.remove(item.id) } }
                        ))
                        .toggleStyle(.checkbox).labelsHidden()

                        Text(item.url.lastPathComponent)
                            .font(.caption).lineLimit(1)
                        Spacer()
                        Text(item.size.formattedSize)
                            .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 4)

                    if item.id != items.prefix(20).last?.id { Divider().padding(.leading, 50) }
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
