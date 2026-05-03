import Foundation
import AppKit

// MARK: - Scan Services

final class ScanServices {

    // MARK: Junk Scan
    static func scanJunk(_ category: JunkCategory) async -> [JunkItem] {
        await Task.detached(priority: .userInitiated) {
            let fm = FileManager.default
            var items: [JunkItem] = []
            for base in category.scanURLs {
                guard fm.fileExists(atPath: base.path) else { continue }
                let entries = (try? fm.contentsOfDirectory(
                    at: base,
                    includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                    options: .skipsHiddenFiles
                )) ?? []
                for url in entries {
                    let sz = dirSize(url, fm: fm)
                    if sz > 0 {
                        items.append(JunkItem(url: url, size: sz, categoryID: category.id))
                    }
                }
            }
            return items.sorted { $0.size > $1.size }
        }.value
    }

    // MARK: Large Files
    static func scanLargeFiles(minMB: Int = 50) async -> [LargeFile] {
        await Task.detached(priority: .utility) {
            let fm = FileManager.default
            let home = fm.homeDirectoryForCurrentUser
            let minSize = Int64(minMB) * 1_048_576
            let scanDirs: [URL] = [
                home.appendingPathComponent("Downloads"),
                home.appendingPathComponent("Documents"),
                home.appendingPathComponent("Desktop"),
                home.appendingPathComponent("Movies"),
                home.appendingPathComponent("Library/Developer"),
            ]
            var files: [LargeFile] = []
            for dir in scanDirs {
                guard let enumerator = fm.enumerator(
                    at: dir,
                    includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .typeIdentifierKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                ) else { continue }
                for case let url as URL in enumerator {
                    guard let vals = try? url.resourceValues(
                        forKeys: [.fileSizeKey, .isDirectoryKey]
                    ),
                    !(vals.isDirectory ?? false),
                    let sz = vals.fileSize,
                    Int64(sz) >= minSize else { continue }
                    files.append(LargeFile(url: url, size: Int64(sz)))
                }
            }
            return Array(files.sorted { $0.size > $1.size }.prefix(400))
        }.value
    }

    // MARK: Apps
    static func scanApps() async -> [AppInfo] {
        await Task.detached(priority: .utility) {
            let fm = FileManager.default
            let home = fm.homeDirectoryForCurrentUser
            let appDirs = [
                URL(fileURLWithPath: "/Applications"),
                home.appendingPathComponent("Applications"),
            ]
            var apps: [AppInfo] = []
            for dir in appDirs {
                guard let contents = try? fm.contentsOfDirectory(
                    at: dir,
                    includingPropertiesForKeys: nil,
                    options: .skipsHiddenFiles
                ) else { continue }
                for appURL in contents where appURL.pathExtension == "app" {
                    let name = appURL.deletingPathExtension().lastPathComponent
                    let bid  = Bundle(url: appURL)?.bundleIdentifier
                    let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                    let sz   = dirSize(appURL, fm: fm)
                    let leftovers = bid.map { findLeftovers(bid: $0, name: name, fm: fm) } ?? []
                    apps.append(AppInfo(
                        url: appURL, name: name, bundleID: bid,
                        icon: icon, appSize: sz, leftovers: leftovers
                    ))
                }
            }
            return apps.sorted { $0.totalSize > $1.totalSize }
        }.value
    }

    private static func findLeftovers(bid: String, name: String, fm: FileManager) -> [LeftoverFile] {
        let home = fm.homeDirectoryForCurrentUser
        let bases: [URL] = [
            home.appendingPathComponent("Library/Application Support"),
            home.appendingPathComponent("Library/Preferences"),
            home.appendingPathComponent("Library/Caches"),
            home.appendingPathComponent("Library/Containers"),
            home.appendingPathComponent("Library/Logs"),
            home.appendingPathComponent("Library/LaunchAgents"),
        ]
        let bidL  = bid.lowercased()
        let nameL = name.lowercased()
        var result: [LeftoverFile] = []
        for base in bases {
            let entries = (try? fm.contentsOfDirectory(
                at: base, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
            )) ?? []
            for url in entries {
                let fn = url.lastPathComponent.lowercased()
                if fn.contains(bidL) || (nameL.count > 4 && fn.contains(nameL)) {
                    let sz = dirSize(url, fm: fm)
                    if sz > 0 { result.append(LeftoverFile(url: url, size: sz)) }
                }
            }
        }
        return result
    }

    // MARK: Privacy
    static func scanPrivacy() async -> [PrivacyGroup] {
        await Task.detached(priority: .utility) {
            let fm   = FileManager.default
            let home = fm.homeDirectoryForCurrentUser
            var groups: [PrivacyGroup] = []

            // Safari
            var safari = PrivacyGroup(browser: .safari)
            for (path, label) in [
                ("Library/Safari/History.db",                  "Browser History"),
                ("Library/Caches/com.apple.Safari",            "Safari Cache"),
                ("Library/WebKit/com.apple.Safari",            "WebKit Data"),
                ("Library/Safari/Downloads.plist",             "Download History"),
                ("Library/Cookies/Cookies.binarycookies",      "Cookies"),
            ] {
                let url = home.appendingPathComponent(path)
                let sz  = dirSize(url, fm: fm)
                if sz > 0 {
                    safari.items.append(PrivacyItem(url: url, size: sz, browser: .safari, label: label))
                }
            }
            groups.append(safari)

            // Chrome
            var chrome = PrivacyGroup(browser: .chrome)
            for (path, label) in [
                ("Library/Application Support/Google/Chrome/Default/History", "Browser History"),
                ("Library/Application Support/Google/Chrome/Default/Cookies", "Cookies"),
                ("Library/Caches/Google/Chrome", "Cache"),
            ] {
                let url = home.appendingPathComponent(path)
                let sz  = dirSize(url, fm: fm)
                if sz > 0 {
                    chrome.items.append(PrivacyItem(url: url, size: sz, browser: .chrome, label: label))
                }
            }
            groups.append(chrome)

            // Firefox
            var firefox = PrivacyGroup(browser: .firefox)
            let ffBase = home.appendingPathComponent("Library/Application Support/Firefox/Profiles")
            if let profiles = try? fm.contentsOfDirectory(
                at: ffBase, includingPropertiesForKeys: nil, options: .skipsHiddenFiles
            ) {
                for profile in profiles {
                    for (name, label) in [
                        ("places.sqlite", "History & Bookmarks"),
                        ("cookies.sqlite", "Cookies"),
                        ("cache2", "Cache"),
                        ("datareporting", "Analytics Data"),
                    ] {
                        let url = profile.appendingPathComponent(name)
                        let sz  = dirSize(url, fm: fm)
                        if sz > 0 {
                            firefox.items.append(PrivacyItem(url: url, size: sz, browser: .firefox, label: label))
                        }
                    }
                }
            }
            groups.append(firefox)

            // System
            var system = PrivacyGroup(browser: .system)
            for (path, label) in [
                ("Library/Application Support/com.apple.sharedfilelist", "Recent Files List"),
                ("Library/Preferences/com.apple.finder.plist", "Finder History"),
                (".bash_history", "Shell History"),
                (".zsh_history", "ZSH History"),
            ] {
                let url = home.appendingPathComponent(path)
                let sz  = dirSize(url, fm: fm)
                if sz > 0 {
                    system.items.append(PrivacyItem(url: url, size: sz, browser: .system, label: label))
                }
            }
            groups.append(system)

            return groups
        }.value
    }

    // MARK: Delete
    static func deleteItems(_ urls: [URL], permanent: Bool = false) async -> Int64 {
        await Task.detached(priority: .userInitiated) {
            var total: Int64 = 0
            for url in urls {
                let sz = dirSize(url, fm: .default)
                do {
                    if permanent {
                        try FileManager.default.removeItem(at: url)
                    } else {
                        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                    }
                    total += sz
                } catch {}
            }
            return total
        }.value
    }

    // MARK: Helpers
    static func dirSize(_ url: URL, fm: FileManager) -> Int64 {
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
            return (try? Int64(url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0)) ?? 0
        }
    }
}
