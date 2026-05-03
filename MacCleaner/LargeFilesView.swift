import SwiftUI

// MARK: - Large Files ViewModel

@MainActor
final class LargeFilesViewModel: ObservableObject {
    @Published var files: [LargeFile] = []
    @Published var scanning = false
    @Published var scanned = false
    @Published var selectedIDs: Set<UUID> = []
    @Published var cleaning = false
    @Published var sortBy: SortKey = .size
    @Published var filter: LargeFileType? = nil

    enum SortKey: String, CaseIterable { case size = "Size", name = "Name", date = "Date" }

    var filtered: [LargeFile] {
        var list = filter == nil ? files : files.filter { $0.type == filter }
        switch sortBy {
        case .size: list.sort { $0.size > $1.size }
        case .name: list.sort { $0.url.lastPathComponent < $1.url.lastPathComponent }
        case .date: list.sort { ($0.modDate ?? .distantPast) > ($1.modDate ?? .distantPast) }
        }
        return list
    }

    var totalSelected: Int64 {
        files.filter { selectedIDs.contains($0.id) }.map(\.size).reduce(0, +)
    }

    func scan() async {
        scanning = true
        scanned = false
        files = await ScanServices.scanLargeFiles()
        scanned = true
        scanning = false
    }

    func clean(appState: AppState) async {
        cleaning = true
        let urls = files.filter { selectedIDs.contains($0.id) }.map(\.url)
        let freed = await ScanServices.deleteItems(urls)
        appState.recordCleaned(freed)
        files.removeAll { selectedIDs.contains($0.id) }
        selectedIDs = []
        cleaning = false
    }
}

// MARK: - Large Files View

struct LargeFilesView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = LargeFilesViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FeatureHeader(nav: .largeFiles)

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

            if vm.scanned && !vm.files.isEmpty {
                actionBar
            }
        }
    }

    // MARK: Splash
    private var splashView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.fill").font(.system(size: 56)).foregroundStyle(.yellow.opacity(0.7))
            Text("Find files larger than 50 MB").font(.title3.weight(.semibold))
            Text("Scans Downloads, Documents, Desktop, Movies, and Developer folders.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button {
                Task { await vm.scan() }
            } label: {
                Label("Scan Large Files", systemImage: "magnifyingglass")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent).tint(.yellow).controlSize(.large)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Scanning
    private var scanningView: some View {
        VStack(spacing: 12) {
            ProgressView().scaleEffect(1.5)
            Text("Scanning for large files…").font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(40)
    }

    // MARK: Results
    @ViewBuilder
    private var resultsView: some View {
        if vm.files.isEmpty {
            EmptyStateView(icon: "checkmark.seal.fill", title: "No large files found",
                           message: "No files over 50 MB in scanned folders.")
        } else {
            // Type filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "All", isOn: vm.filter == nil) { vm.filter = nil }
                    ForEach(LargeFileType.allCases, id: \.self) { type in
                        FilterChip(label: type.label, isOn: vm.filter == type) {
                            vm.filter = vm.filter == type ? nil : type
                        }
                    }
                }
                .padding(.horizontal, 2)
            }

            // Sort picker
            HStack {
                Picker("Sort", selection: $vm.sortBy) {
                    ForEach(LargeFilesViewModel.SortKey.allCases, id: \.self) { k in
                        Text(k.rawValue).tag(k)
                    }
                }
                .pickerStyle(.segmented).frame(width: 200)
                Spacer()
                Text("\(vm.filtered.count) files")
                    .font(.caption).foregroundStyle(.secondary)
            }

            // File list
            LazyVStack(spacing: 4) {
                ForEach(vm.filtered) { file in
                    LargeFileRow(file: file, isSelected: vm.selectedIDs.contains(file.id)) {
                        if vm.selectedIDs.contains(file.id) { vm.selectedIDs.remove(file.id) }
                        else { vm.selectedIDs.insert(file.id) }
                    }
                }
            }
        }
    }

    // MARK: Action Bar
    private var actionBar: some View {
        HStack {
            Button(vm.selectedIDs.count == vm.files.count ? "Deselect All" : "Select All") {
                if vm.selectedIDs.count == vm.files.count {
                    vm.selectedIDs = []
                } else {
                    vm.selectedIDs = Set(vm.files.map(\.id))
                }
            }
            .buttonStyle(.bordered).controlSize(.small)

            Spacer()
            Text("\(vm.selectedIDs.count) selected · \(vm.totalSelected.formattedSize)")
                .font(.caption).foregroundStyle(.secondary)
            Spacer()

            Button {
                Task { await vm.clean(appState: appState) }
            } label: {
                if vm.cleaning {
                    ProgressView().controlSize(.small)
                } else {
                    Label("Remove", systemImage: "trash")
                }
            }
            .buttonStyle(.borderedProminent).tint(.red)
            .disabled(vm.selectedIDs.isEmpty || vm.cleaning)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(.bar)
    }
}

// MARK: - Large File Row

private struct LargeFileRow: View {
    let file: LargeFile
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.system(size: 16))
                Image(systemName: file.type.icon)
                    .foregroundStyle(file.type.color)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.url.lastPathComponent).font(.subheadline).lineLimit(1)
                    Text(file.url.deletingLastPathComponent().path)
                        .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(file.size.formattedSize)
                        .font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    if let d = file.modDate {
                        Text(d, style: .date).font(.caption2).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 9)
            .background(isSelected ? Color.blue.opacity(0.06) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.06), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(isOn ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.06),
                            in: Capsule())
                .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
                .overlay(Capsule().stroke(isOn ? Color.accentColor.opacity(0.3) : .clear, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
