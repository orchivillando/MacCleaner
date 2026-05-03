import Foundation
import SwiftUI

// MARK: - Global App State

@MainActor
final class AppState: ObservableObject {
    @Published var diskInfo: DiskInfo?
    @Published var memoryInfo: MemoryInfo?
    @Published var totalCleaned: Int64 = 0
    @Published var lastCleanDate: Date?
    @Published var selectedNav: NavDestination = .dashboard

    private var timer: Timer?

    init() {
        refreshStats()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshStats() }
        }
    }

    deinit { timer?.invalidate() }

    func refreshStats() {
        diskInfo   = SystemService.getDiskInfo()
        memoryInfo = SystemService.getMemoryInfo()
    }

    func recordCleaned(_ bytes: Int64) {
        totalCleaned += bytes
        lastCleanDate = Date()
        refreshStats()
    }

    var diskWarning: Bool { (diskInfo?.freeFraction ?? 1.0) < 0.15 }

    var formattedTotalCleaned: String {
        ByteCountFormatter.string(fromByteCount: totalCleaned, countStyle: .file)
    }
}

// MARK: - Navigation

enum NavDestination: String, Hashable, CaseIterable {
    case dashboard, smartScan, systemJunk, largeFiles, apps, privacy, memory, maintenance

    var label: String {
        switch self {
        case .dashboard:   return "Dashboard"
        case .smartScan:   return "Smart Scan"
        case .systemJunk:  return "System Junk"
        case .largeFiles:  return "Large Files"
        case .apps:        return "App Uninstaller"
        case .privacy:     return "Privacy"
        case .memory:      return "Memory"
        case .maintenance: return "Maintenance"
        }
    }

    var icon: String {
        switch self {
        case .dashboard:   return "gauge.medium"
        case .smartScan:   return "sparkle.magnifyingglass"
        case .systemJunk:  return "trash.fill"
        case .largeFiles:  return "doc.fill"
        case .apps:        return "xmark.app.fill"
        case .privacy:     return "lock.shield.fill"
        case .memory:      return "memorychip"
        case .maintenance: return "wrench.and.screwdriver.fill"
        }
    }

    var color: Color {
        switch self {
        case .dashboard:   return .blue
        case .smartScan:   return .purple
        case .systemJunk:  return .orange
        case .largeFiles:  return .yellow
        case .apps:        return .red
        case .privacy:     return .green
        case .memory:      return .mint
        case .maintenance: return .brown
        }
    }

    var description: String {
        switch self {
        case .dashboard:   return "Overview & quick actions"
        case .smartScan:   return "Scan all junk at once"
        case .systemJunk:  return "Caches, logs & temp files"
        case .largeFiles:  return "Files larger than 50 MB"
        case .apps:        return "Apps & their leftovers"
        case .privacy:     return "Browser & system history"
        case .memory:      return "RAM usage & optimization"
        case .maintenance: return "System maintenance tasks"
        }
    }
}
