import Foundation
import SwiftUI
import AppKit

// MARK: - Junk Category

struct JunkCategory: Identifiable {
    let id: String
    let label: String
    let description: String
    let icon: String
    let color: Color
    let scanURLs: [URL]

    static var all: [JunkCategory] {
        let fm   = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        return [
            JunkCategory(id: "user_caches",    label: "User Caches",       description: "App cache data",
                         icon: "archivebox.fill",           color: .blue,
                         scanURLs: [home.appendingPathComponent("Library/Caches")]),
            JunkCategory(id: "user_logs",      label: "User Logs",         description: "Application logs",
                         icon: "doc.text.fill",             color: .orange,
                         scanURLs: [home.appendingPathComponent("Library/Logs")]),
            JunkCategory(id: "temp_files",     label: "Temp Files",        description: "System temp files",
                         icon: "clock.badge.xmark",         color: .purple,
                         scanURLs: [URL(fileURLWithPath: "/tmp"),
                                    home.appendingPathComponent("Library/Temp")]),
            JunkCategory(id: "trash",          label: "Trash",             description: "Files in Trash",
                         icon: "trash.fill",                color: .red,
                         scanURLs: [home.appendingPathComponent(".Trash")]),
            JunkCategory(id: "mail_downloads", label: "Mail Downloads",    description: "Email attachments",
                         icon: "envelope.fill",             color: .cyan,
                         scanURLs: [home.appendingPathComponent("Library/Mail Downloads")]),
            JunkCategory(id: "xcode_derived",  label: "Xcode DerivedData", description: "Xcode build data",
                         icon: "hammer.fill",               color: .indigo,
                         scanURLs: [home.appendingPathComponent("Library/Developer/Xcode/DerivedData")]),
            JunkCategory(id: "xcode_archives", label: "Xcode Archives",    description: "Archived builds",
                         icon: "archivebox",                color: Color(red: 0.4, green: 0.3, blue: 0.9),
                         scanURLs: [home.appendingPathComponent("Library/Developer/Xcode/Archives")]),
            JunkCategory(id: "ios_simulator",  label: "iOS Simulator",     description: "Simulator caches",
                         icon: "iphone",                    color: .teal,
                         scanURLs: [home.appendingPathComponent("Library/Developer/CoreSimulator/Caches")]),
            JunkCategory(id: "app_cookies",    label: "App Cookies",       description: "Local cookies",
                         icon: "square.grid.3x3.fill",      color: .pink,
                         scanURLs: [home.appendingPathComponent("Library/Cookies"),
                                    home.appendingPathComponent("Library/HTTPStorages")]),
        ]
    }
}

// MARK: - Junk Item

struct JunkItem: Identifiable {
    let id = UUID()
    let url: URL
    let size: Int64
    let categoryID: String
}

// MARK: - Large File

enum LargeFileType: String, CaseIterable {
    case video, audio, document, image, archive, development, other

    var label: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .video: return "video.fill"; case .audio: return "music.note"
        case .document: return "doc.text.fill"; case .image: return "photo.fill"
        case .archive: return "archivebox.fill"
        case .development: return "chevron.left.forwardslash.chevron.right"
        case .other: return "doc.fill"
        }
    }

    var color: Color {
        switch self {
        case .video: return .red; case .audio: return .pink
        case .document: return .blue; case .image: return .green
        case .archive: return .orange; case .development: return .purple
        case .other: return .secondary
        }
    }

    static func detect(url: URL) -> LargeFileType {
        let ext = url.pathExtension.lowercased()
        if ["mp4","mov","avi","mkv","m4v","wmv","m2ts"].contains(ext) { return .video }
        if ["mp3","aac","flac","wav","m4a","ogg","aiff"].contains(ext) { return .audio }
        if ["pdf","doc","docx","xls","xlsx","ppt","pptx","pages","numbers","key","txt"].contains(ext) { return .document }
        if ["jpg","jpeg","png","gif","heic","tiff","webp","psd","raw","cr2"].contains(ext) { return .image }
        if ["zip","tar","gz","bz2","7z","rar","dmg","iso","pkg"].contains(ext) { return .archive }
        if ["xcarchive","xcodeproj","dSYM","ipa"].contains(ext) { return .development }
        return .other
    }
}

struct LargeFile: Identifiable {
    let id = UUID()
    let url: URL
    let size: Int64
    var type: LargeFileType { LargeFileType.detect(url: url) }
    var modDate: Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }
}

// MARK: - App Info

struct LeftoverFile: Identifiable {
    let id = UUID()
    let url: URL
    let size: Int64
}

struct AppInfo: Identifiable {
    let id = UUID()
    let url: URL
    let name: String
    let bundleID: String?
    let icon: NSImage
    let appSize: Int64
    let leftovers: [LeftoverFile]
    var totalSize: Int64 { appSize + leftovers.map(\.size).reduce(0, +) }
}

// MARK: - Privacy

enum BrowserType: CaseIterable {
    case safari, chrome, firefox, system

    var label: String {
        switch self {
        case .safari:  return "Safari"
        case .chrome:  return "Google Chrome"
        case .firefox: return "Firefox"
        case .system:  return "System History"
        }
    }

    var icon: String {
        switch self {
        case .safari:  return "safari.fill"
        case .chrome:  return "globe"
        case .firefox: return "flame.fill"
        case .system:  return "clock.fill"
        }
    }

    var color: Color {
        switch self {
        case .safari:  return .blue
        case .chrome:  return .green
        case .firefox: return .orange
        case .system:  return .gray
        }
    }
}

struct PrivacyItem: Identifiable {
    let id = UUID()
    let url: URL
    let size: Int64
    let browser: BrowserType
    let label: String
}

struct PrivacyGroup: Identifiable {
    let id = UUID()
    let browser: BrowserType
    var items: [PrivacyItem] = []
}
