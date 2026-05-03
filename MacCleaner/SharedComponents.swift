import SwiftUI

// MARK: - Ring / Gauge View

struct RingView: View {
    let fraction: Double
    let color: Color
    var lineWidth: CGFloat = 12
    var size: CGFloat = 100

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(fraction, 1)))
                .stroke(
                    AngularGradient(colors: [color.opacity(0.7), color], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: fraction)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Feature Header

struct FeatureHeader: View {
    let nav: NavDestination

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(nav.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: nav.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(nav.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(nav.label)
                    .font(.title2.weight(.bold))
                Text(nav.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Size Bar

struct SizeBar: View {
    let fraction: Double
    let color: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.15)).frame(height: height)
                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * CGFloat(min(fraction, 1)), height: height)
                    .animation(.easeInOut(duration: 0.5), value: fraction)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    enum Status { case clean, warning, danger }
    let status: Status

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
            Text(statusLabel)
                .font(.caption.weight(.medium))
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(statusColor.opacity(0.12), in: Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .clean:   return .green
        case .warning: return .orange
        case .danger:  return .red
        }
    }
    private var statusLabel: String {
        switch status {
        case .clean:   return "Clean"
        case .warning: return "Needs Attention"
        case .danger:  return "Critical"
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Formatted Size

extension Int64 {
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: self, countStyle: .file)
    }
}

// MARK: - Section Label

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.top, 10)
    }
}
