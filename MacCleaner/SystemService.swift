import Foundation
import Darwin

// MARK: - Disk Info

struct DiskInfo {
    let total: Int64
    let free: Int64
    var used: Int64 { total - free }
    var usedFraction: Double { Double(used) / Double(max(total, 1)) }
    var freeFraction: Double { Double(free) / Double(max(total, 1)) }
    var formattedFree: String  { fmt(free) }
    var formattedUsed: String  { fmt(used) }
    var formattedTotal: String { fmt(total) }
    private func fmt(_ n: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: n, countStyle: .file)
    }
}

// MARK: - Memory Info

struct MemoryInfo {
    let total: UInt64
    let active: UInt64
    let inactive: UInt64
    let wired: UInt64
    let compressed: UInt64
    let free: UInt64

    var used: UInt64 { active + wired + compressed }
    var usedFraction: Double { Double(used) / Double(max(total, 1)) }

    var formattedTotal:      String { fmt(total) }
    var formattedUsed:       String { fmt(used) }
    var formattedFree:       String { fmt(free) }
    var formattedActive:     String { fmt(active) }
    var formattedInactive:   String { fmt(inactive) }
    var formattedWired:      String { fmt(wired) }
    var formattedCompressed: String { fmt(compressed) }

    private func fmt(_ n: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(n), countStyle: .memory)
    }
}

// MARK: - System Service

final class SystemService {

    static func getDiskInfo() -> DiskInfo? {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
              let total = attrs[.systemSize] as? Int64,
              let free  = attrs[.systemFreeSize] as? Int64
        else { return nil }
        return DiskInfo(total: total, free: free)
    }

    static func getMemoryInfo() -> MemoryInfo {
        let ps = UInt64(vm_kernel_page_size)
        var s  = vm_statistics64()
        var c  = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )
        withUnsafeMutablePointer(to: &s) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(c)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &c)
            }
        }
        let total = ProcessInfo.processInfo.physicalMemory
        return MemoryInfo(
            total:      total,
            active:     UInt64(s.active_count) * ps,
            inactive:   UInt64(s.inactive_count) * ps,
            wired:      UInt64(s.wire_count) * ps,
            compressed: UInt64(s.compressor_page_count) * ps,
            free:       UInt64(s.free_count) * ps
        )
    }

    @discardableResult
    static func run(_ exe: String, args: [String]) -> Bool {
        let searchPaths = ["/usr/bin", "/bin", "/usr/sbin", "/usr/local/bin"]
        guard let full = searchPaths
            .map({ "\($0)/\(exe)" })
            .first(where: { FileManager.default.fileExists(atPath: $0) })
        else { return false }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: full)
        p.arguments = args
        p.standardOutput = FileHandle.nullDevice
        p.standardError  = FileHandle.nullDevice
        do { try p.run(); p.waitUntilExit(); return p.terminationStatus == 0 }
        catch { return false }
    }

    @discardableResult
    static func runWithAdmin(_ command: String) -> Bool {
        let escaped = command.replacingOccurrences(of: "\"", with: "\\\"")
        let script = "do shell script \"\(escaped)\" with administrator privileges"
        var err: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&err)
        return err == nil
    }
}
