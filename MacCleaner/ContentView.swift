import SwiftUI

// MARK: - Root View

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 260)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedNav {
        case .dashboard:   DashboardView()
        case .smartScan:   SmartScanView()
        case .systemJunk:  SystemJunkView()
        case .largeFiles:  LargeFilesView()
        case .apps:        AppUninstallerView()
        case .privacy:     PrivacyView()
        case .memory:      MemoryView()
        case .maintenance: MaintenanceView()
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // App header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient(colors: [.blue, .purple],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 36, height: 36)
                    Image(systemName: "sparkles")
                        .foregroundStyle(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text("MacCleaner").font(.headline)
                    Text("v2.0 Enterprise").font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 12)

            Divider()

            List(selection: Binding(
                get: { appState.selectedNav },
                set: { if let v = $0 { appState.selectedNav = v } }
            )) {
                SidebarSection(title: "Overview") {
                    NavRow(nav: .dashboard)
                    NavRow(nav: .smartScan)
                }
                SidebarSection(title: "Clean") {
                    NavRow(nav: .systemJunk)
                    NavRow(nav: .largeFiles)
                    NavRow(nav: .apps)
                }
                SidebarSection(title: "Privacy & System") {
                    NavRow(nav: .privacy)
                    NavRow(nav: .memory)
                    NavRow(nav: .maintenance)
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Disk mini bar
            if let disk = appState.diskInfo {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Disk").font(.caption2).foregroundStyle(.secondary)
                        Spacer()
                        Text(disk.formattedFree + " free")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    SizeBar(fraction: disk.usedFraction,
                            color: disk.freeFraction < 0.15 ? .red : .blue)
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sidebar Section

struct SidebarSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        Section {
            content
        } header: {
            Text(title)
        }
    }
}

// MARK: - Nav Row

struct NavRow: View {
    let nav: NavDestination

    var body: some View {
        Label {
            Text(nav.label)
        } icon: {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(nav.color.opacity(0.15))
                    .frame(width: 22, height: 22)
                Image(systemName: nav.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(nav.color)
            }
        }
        .tag(nav)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .frame(width: 920, height: 640)
}

