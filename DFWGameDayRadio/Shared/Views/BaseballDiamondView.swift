import SwiftUI

/// Baseball diamond showing base runners, count, and outs.
struct BaseballDiamondView: View {
    let situation: BaseballSituation
    var compact: Bool = false

    @ScaledMetric private var diamondSize: CGFloat = 60
    @ScaledMetric private var compactDiamondSize: CGFloat = 32
    @ScaledMetric private var dotSize: CGFloat = 8
    @ScaledMetric private var compactDotSize: CGFloat = 6

    private var baseRunnerDescription: String {
        var runners: [String] = []
        if situation.runnerOnFirst { runners.append("first") }
        if situation.runnerOnSecond { runners.append("second") }
        if situation.runnerOnThird { runners.append("third") }
        if runners.isEmpty { return "Bases empty" }
        return "Runners on \(runners.joined(separator: " and "))"
    }

    var body: some View {
        if compact {
            compactLayout
        } else {
            fullLayout
        }
    }

    // MARK: - Full Layout

    private var fullLayout: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                diamondGraphic
                    .frame(width: diamondSize, height: diamondSize)
                    .accessibilityLabel(baseRunnerDescription)

                VStack(alignment: .leading, spacing: 4) {
                    Text(situation.inningDisplay)
                        .font(.subheadline.bold())

                    countDots

                    outsDots
                }
            }

            if !situation.batterName.isEmpty || !situation.pitcherName.isEmpty {
                HStack(spacing: 16) {
                    if !situation.batterName.isEmpty {
                        Label(situation.batterName, systemImage: "figure.baseball")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if !situation.pitcherName.isEmpty {
                        Label(situation.pitcherName, systemImage: "baseball")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Compact Layout (for Live Activity)

    private var compactLayout: some View {
        HStack(spacing: 8) {
            diamondGraphic
                .frame(width: compactDiamondSize, height: compactDiamondSize)
                .accessibilityLabel(baseRunnerDescription)

            VStack(alignment: .leading, spacing: 2) {
                countDots
                outsDots
            }
        }
    }

    // MARK: - Diamond Graphic

    private var diamondGraphic: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            let radius = size * 0.4

            Canvas { context, _ in
                // Draw diamond outline
                let diamondPath = Path { path in
                    path.move(to: CGPoint(x: center.x, y: center.y - radius))    // 2B (top)
                    path.addLine(to: CGPoint(x: center.x + radius, y: center.y)) // 1B (right)
                    path.addLine(to: CGPoint(x: center.x, y: center.y + radius)) // Home (bottom)
                    path.addLine(to: CGPoint(x: center.x - radius, y: center.y)) // 3B (left)
                    path.closeSubpath()
                }
                context.stroke(diamondPath, with: .color(.secondary.opacity(0.4)), lineWidth: 1.5)

                // Base positions
                let baseSize: CGFloat = size * 0.14
                let bases: [(CGPoint, Bool)] = [
                    (CGPoint(x: center.x + radius, y: center.y), situation.runnerOnFirst),   // 1B
                    (CGPoint(x: center.x, y: center.y - radius), situation.runnerOnSecond),  // 2B
                    (CGPoint(x: center.x - radius, y: center.y), situation.runnerOnThird),   // 3B
                ]

                for (point, occupied) in bases {
                    let basePath = Path { path in
                        let half = baseSize / 2
                        path.move(to: CGPoint(x: point.x, y: point.y - half))
                        path.addLine(to: CGPoint(x: point.x + half, y: point.y))
                        path.addLine(to: CGPoint(x: point.x, y: point.y + half))
                        path.addLine(to: CGPoint(x: point.x - half, y: point.y))
                        path.closeSubpath()
                    }

                    if occupied {
                        context.fill(basePath, with: .color(.yellow))
                    }
                    context.stroke(basePath, with: .color(.secondary.opacity(0.6)), lineWidth: 1)
                }

                // Home plate
                let homePoint = CGPoint(x: center.x, y: center.y + radius)
                let homeSize = baseSize * 0.8
                let homePath = Path { path in
                    let half = homeSize / 2
                    path.move(to: CGPoint(x: homePoint.x, y: homePoint.y - half))
                    path.addLine(to: CGPoint(x: homePoint.x + half, y: homePoint.y))
                    path.addLine(to: CGPoint(x: homePoint.x, y: homePoint.y + half))
                    path.addLine(to: CGPoint(x: homePoint.x - half, y: homePoint.y))
                    path.closeSubpath()
                }
                context.stroke(homePath, with: .color(.secondary.opacity(0.6)), lineWidth: 1)
            }
        }
    }

    // MARK: - Count and Outs

    private var countDots: some View {
        let currentDotSize = compact ? compactDotSize : dotSize
        return HStack(spacing: 12) {
            HStack(spacing: 2) {
                Text("B")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < situation.balls ? Color.green : Color(.tertiarySystemFill))
                        .frame(width: currentDotSize, height: currentDotSize)
                }
                Text("\(situation.balls)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 2) {
                Text("S")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i < situation.strikes ? Color.red : Color(.tertiarySystemFill))
                        .frame(width: currentDotSize, height: currentDotSize)
                }
                Text("\(situation.strikes)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(situation.balls) balls, \(situation.strikes) strikes")
    }

    private var outsDots: some View {
        let currentDotSize = compact ? compactDotSize : dotSize
        return HStack(spacing: 2) {
            Text("O")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(i < situation.outs ? Color.orange : Color(.tertiarySystemFill))
                    .frame(width: currentDotSize, height: currentDotSize)
            }
            Text("\(situation.outs)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(situation.outs) outs")
    }
}
