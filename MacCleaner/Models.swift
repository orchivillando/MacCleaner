import Foundation
import SwiftUI

// MARK: - Category

enum CleanupCategory: String, CaseIterable, Identifiable {
    case userCaches  = "User Caches"
    case userLogs    = "User Logs"
    case tempFiles   = "Temp Files"
    case trash       = "Sampah (Trash)"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .userCaches: return "archivebox.fill"
        case .userLogs:   return "doc.text.fill"
        case .tempFiles:  return "clock.badge.xmark.fill"
        case .trash:      return "trash.fill"
        }
    }

    var color: Color {
        switch self {
        case .userCaches: return .blue
        case .userLogs:   return .orange
        case .tempFiles:  return .purple
        case .trash:      return .red
        }
    }

    var subtitle: String {
        switch self {
        case .userCaches: return "~/Library/Caches"
        case .userLogs:   return "~/Library/Logs"
        case .tempFiles:  return "/tmp"
        case .trash:      return "~/.Trash"
        }
    }

    var scanPaths: [URL] {
        let fm   = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        switch self {
        case .userCaches: return [home.appendingPathComponent("Library/Caches")]
        case .userLogs:   return [home.appendingPathComponent("Library/Logs")]
        case .tempFiles:  return [URL(fileURLWithPath: "/tmp")]
        case .trash:      return [home.appendingPathComponent(".Trash")]
        }
    }
}

// MARK: - Item

struct CleanupItem: Identifiable, Hashable {
    let id   = UUID()
    let url  : URL
    let size : Int64
    let category: CleanupCategory

    var name: String { url.lastPathComponent }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var isDirectory: Bool {
        var dir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &dir)
        return dir.boolValue
    }
}

// MARK: - Category State

struct CategoryState: Identifiable {
    let category : CleanupCategory
    var items     : [CleanupItem] = []
    var isSelected: Bool = true
    var isScanned : Bool = false

    var id: String { category.id }

    var totalSize: Int64 { items.reduce(0) { $0 + $1.size } }

    var formattedTotalSize: String {
        guard totalSize > 0 else { return "Kosong" }
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}
