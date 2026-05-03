import SwiftUI

// MARK: - Root

struct ContentView: View {
    @StateObject private var vm = CleanerViewModel()

    var body: some View {
        NavigationSplitView {
            SidebarView(vm: vm)
                .navigationSplitViewColumnWidth(min: 210, ideal: 230, max: 270)
        } detail: {
            if let cat = vm.selectedCategory, let state = vm.state(for: cat) {
                DetailView(state: state)
            } else {
                WelcomeView(vm: vm)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if vm.isScanning || vm.isCleaning {
                    ProgressView()
                        .scaleEffect(0.75)
                        .frame(width: 20, height: 20)
                }
                Button { Task { await vm.scan() } } label: {
                    Label("Scan", systemImage: "magnifyingglass")
                }
                .disabled(vm.isScanning || vm.isCleaning)
                .help("Cari file sampah")

                Button { Task { await vm.clean() } } label: {
                    Label("Bersihkan", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(vm.isScanning || vm.isCleaning || vm.totalSelectedSize == 0)
                .help("Hapus semua file yang dipilih")
            }
        }
        .alert("Pembersihan Selesai! 🎉", isPresented: $vm.showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Berhasil membebaskan \(ByteCountFormatter.string(fromByteCount: vm.lastCleanedSize, countStyle: .file)) ruang penyimpanan.")
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @ObservedObject var vm: CleanerViewModel

    var body: some View {
        VStack(spacing: 0) {
            List(vm.categoryStates, selection: $vm.selectedCategory) { state in
                CategoryRow(state: state, vm: vm)
                    .tag(state.category)
            }
            .listStyle(.sidebar)

            Divider()

            // Status panel
            VStack(spacing: 6) {
                if vm.isScanning {
                    ProgressView(value: vm.scanProgress)
                        .progressViewStyle(.linear)
                        .animation(.spring(), value: vm.scanProgress)
                }
                if vm.totalCleaned > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green).font(.caption)
                        Text("Dibersihkan: \(ByteCountFormatter.string(fromByteCount: vm.totalCleaned, countStyle: .file))")
                            .font(.caption).foregroundColor(.green)
                    }
                }
                Text(vm.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Mac Cleaner")
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let state: CategoryState
    @ObservedObject var vm: CleanerViewModel

    var body: some View {
        HStack(spacing: 8) {
            Button { vm.toggleSelect(state.category) } label: {
                Image(systemName: state.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(state.isSelected ? state.category.color : .secondary.opacity(0.4))
                    .font(.system(size: 15))
                    .animation(.spring(response: 0.25), value: state.isSelected)
            }
            .buttonStyle(.plain)

            ZStack {
                RoundedRectangle(cornerRadius: 7)
                    .fill(state.category.color.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: state.category.icon)
                    .foregroundColor(state.category.color)
                    .font(.system(size: 14))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(state.category.rawValue)
                    .font(.system(size: 13, weight: .medium))
                if state.isScanned {
                    Text(state.formattedTotalSize)
                        .font(.system(size: 11))
                        .foregroundColor(state.totalSize > 0 ? state.category.color : .secondary)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: state.isScanned)

            Spacer()

            if state.isScanned && !state.items.isEmpty {
                Text("\(state.items.count)")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(state.category.color.opacity(0.2))
                    .foregroundColor(state.category.color)
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Detail (file list)

struct DetailView: View {
    let state: CategoryState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(state.category.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: state.category.icon)
                        .foregroundColor(state.category.color)
                        .font(.title2)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(state.category.rawValue)
                        .font(.title2.weight(.semibold))
                    Text(state.category.subtitle)
                        .font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                if state.totalSize > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(state.formattedTotalSize)
                            .font(.title3.weight(.bold))
                            .foregroundColor(state.category.color)
                        Text("\(state.items.count) item")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            Divider()

            if state.items.isEmpty {
                EmptyStateView(isScanned: state.isScanned)
            } else {
                List(state.items) { item in
                    ItemRow(item: item)
                }
                .listStyle(.inset)
            }
        }
    }
}

// MARK: - File Row

struct ItemRow: View {
    let item: CleanupItem
    private let homePrefix = FileManager.default.homeDirectoryForCurrentUser.path

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                .foregroundColor(item.isDirectory ? .yellow : .secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13)).lineLimit(1)
                Text(item.url.deletingLastPathComponent().path
                    .replacingOccurrences(of: homePrefix, with: "~"))
                    .font(.system(size: 10)).foregroundColor(.secondary).lineLimit(1)
            }

            Spacer()

            SizeBar(size: item.size)

            Text(item.formattedSize)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .monospacedDigit()
                .frame(minWidth: 64, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Size Bar

struct SizeBar: View {
    let size: Int64
    private let cap: Double = 1_500_000_000

    var fraction: Double { min(Double(size) / cap, 1.0) }
    var color: Color {
        fraction > 0.6 ? .red : fraction > 0.25 ? .orange : .blue
    }

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(Color.secondary.opacity(0.12))
                RoundedRectangle(cornerRadius: 2).fill(color.opacity(0.65))
                    .frame(width: g.size.width * fraction)
            }
        }
        .frame(width: 56, height: 6)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let isScanned: Bool

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: isScanned ? "checkmark.seal.fill" : "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(isScanned ? .green : .secondary)
            Text(isScanned ? "Bersih! 🎉" : "Belum di-scan")
                .font(.title2.weight(.semibold))
                .foregroundColor(isScanned ? .primary : .secondary)
            Text(isScanned
                 ? "Tidak ada file sampah di kategori ini"
                 : "Klik 'Scan' di toolbar untuk mulai pencarian")
                .font(.body).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Welcome

struct WelcomeView: View {
    @ObservedObject var vm: CleanerViewModel

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.blue.opacity(0.15), .purple.opacity(0.15)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 110, height: 110)
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing))
            }

            VStack(spacing: 8) {
                Text("Mac Cleaner")
                    .font(.largeTitle.weight(.bold))
                Text("Bersihkan Mac Anda dari file-file yang tidak dibutuhkan\ndan bebaskan ruang penyimpanan")
                    .font(.callout).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Category list
            VStack(spacing: 0) {
                ForEach(CleanupCategory.allCases) { cat in
                    HStack(spacing: 12) {
                        Image(systemName: cat.icon)
                            .foregroundColor(cat.color).frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cat.rawValue).font(.system(size: 13, weight: .medium))
                            Text(cat.subtitle).font(.system(size: 11)).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 9)
                    if cat != CleanupCategory.allCases.last {
                        Divider().padding(.leading, 50)
                    }
                }
            }
            .background(.background.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
            .frame(maxWidth: 380)

            Button { Task { await vm.scan() } } label: {
                Label("Mulai Scan Sekarang", systemImage: "magnifyingglass.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 32).padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isScanning)

            Spacer()
        }
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView().frame(width: 820, height: 560)
}
