import Foundation
import SwiftUI

@MainActor
class CleanerViewModel: ObservableObject {

    @Published var categoryStates: [CategoryState] =
        CleanupCategory.allCases.map { CategoryState(category: $0) }

    @Published var selectedCategory : CleanupCategory? = nil
    @Published var isScanning       = false
    @Published var isCleaning       = false
    @Published var scanProgress     : Double = 0
    @Published var statusMessage    = "Klik 'Scan' untuk mencari file sampah"
    @Published var totalCleaned     : Int64 = 0
    @Published var showSuccessAlert = false
    @Published var lastCleanedSize  : Int64 = 0

    // MARK: Computed

    var totalSelectedSize: Int64 {
        categoryStates.filter { $0.isSelected }.reduce(0) { $0 + $1.totalSize }
    }

    var formattedTotal: String {
        ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file)
    }

    var hasData: Bool { categoryStates.contains { $0.isScanned } }

    func state(for cat: CleanupCategory) -> CategoryState? {
        categoryStates.first { $0.category == cat }
    }

    // MARK: Actions

    func toggleSelect(_ cat: CleanupCategory) {
        guard let i = categoryStates.firstIndex(where: { $0.category == cat }) else { return }
        categoryStates[i].isSelected.toggle()
    }

    func scan() async {
        guard !isScanning, !isCleaning else { return }
        isScanning    = true
        scanProgress  = 0
        statusMessage = "Sedang scanning..."

        for i in categoryStates.indices {
            categoryStates[i].items    = []
            categoryStates[i].isScanned = false
        }

        let total = Double(categoryStates.count)
        for (i, state) in categoryStates.enumerated() {
            statusMessage = "Scanning \(state.category.rawValue)..."
            let items = await Task.detached(priority: .userInitiated) {
                CleanerViewModel.scanCategory(state.category)
            }.value
            categoryStates[i].items     = items
            categoryStates[i].isScanned = true
            scanProgress = Double(i + 1) / total
        }

        isScanning = false
        if totalSelectedSize > 0 {
            statusMessage = "Ditemukan \(formattedTotal) file sampah 🗑"
        } else {
            statusMessage = "Mac Anda sudah bersih! ✨"
        }
    }

    func clean() async {
        guard !isCleaning, !isScanning, totalSelectedSize > 0 else { return }
        isCleaning    = true
        statusMessage = "Membersihkan..."
        var cleaned: Int64 = 0

        for i in categoryStates.indices {
            guard categoryStates[i].isSelected else { continue }
            let isPermanent = categoryStates[i].category == .trash
            for item in categoryStates[i].items {
                do {
                    if isPermanent {
                        try FileManager.default.removeItem(at: item.url)
                    } else {
                        try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
                    }
                    cleaned += item.size
                } catch { /* skip items we can't delete */ }
            }
            categoryStates[i].items     = []
            categoryStates[i].isScanned = false
        }

        totalCleaned   += cleaned
        lastCleanedSize = cleaned
        isCleaning      = false
        selectedCategory = nil
        scanProgress    = 0

        let str = ByteCountFormatter.string(fromByteCount: cleaned, countStyle: .file)
        statusMessage   = "✅ Berhasil membersihkan \(str)"
        showSuccessAlert = true
    }

    // MARK: Scanning (off main actor)

    private nonisolated static func scanCategory(_ cat: CleanupCategory) -> [CleanupItem] {
        let fm = FileManager.default
        var items: [CleanupItem] = []
        for base in cat.scanPaths {
            guard fm.fileExists(atPath: base.path) else { continue }
            let entries = (try? fm.contentsOfDirectory(
                at: base,
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                options: .skipsHiddenFiles
            )) ?? []
            for url in entries {
                let sz = fileSize(url, fm)
                if sz > 0 { items.append(CleanupItem(url: url, size: sz, category: cat)) }
            }
        }
        return items.sorted { $0.size > $1.size }
    }

    private nonisolated static func fileSize(_ url: URL, _ fm: FileManager) -> Int64 {
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        if isDir.boolValue {
            guard let e = fm.enumerator(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { return 0 }
            var total: Int64 = 0
            for case let f as URL in e {
                if let s = try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    total += Int64(s)
                }
            }
            return total
        } else {
            if let s = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize { return Int64(s) }
            return 0
        }
    }
}
