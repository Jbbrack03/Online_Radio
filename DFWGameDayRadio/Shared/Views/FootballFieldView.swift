import SwiftUI

/// Football field position showing down, distance, and yard line.
struct FootballFieldView: View {
    let situation: FootballSituation
    var compact: Bool = false

    @ScaledMetric private var barHeight: CGFloat = 24
    @ScaledMetric private var markerSize: CGFloat = 12

    var body: some View {
        if compact {
            compactLayout
        } else {
            fullLayout
        }
    }

    // MARK: - Full Layout

    private var fullLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(situation.fieldPosition)
                .font(.subheadline.bold())

            fieldBar
                .frame(height: barHeight)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Ball at the \(situation.yardLine) yard line")

            if let lastPlay = situation.lastPlay, !lastPlay.isEmpty {
                Text(lastPlay)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    // MARK: - Compact Layout

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(situation.downAndDistance)
                .font(.caption.bold())
            Text("\(situation.possession) \(situation.yardLine)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Field Bar

    private var fieldBar: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack(alignment: .leading) {
                // Field background — adapts to color scheme
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green.opacity(0.25))
                    .overlay {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    }

                // Yard line markers (every 10 yards)
                ForEach(1..<10, id: \.self) { i in
                    let x = width * CGFloat(i) / 10.0
                    Rectangle()
                        .fill(Color.primary.opacity(0.12))
                        .frame(width: 1, height: height)
                        .offset(x: x)
                }

                // 50 yard line
                Rectangle()
                    .fill(Color.primary.opacity(0.25))
                    .frame(width: 2, height: height)
                    .offset(x: width / 2)

                // Ball position marker
                let yardPosition = CGFloat(situation.yardLine) / 50.0
                let clampedPosition = min(max(yardPosition, 0), 1)
                Circle()
                    .fill(Color.orange)
                    .frame(width: markerSize, height: markerSize)
                    .shadow(color: .orange.opacity(0.5), radius: 3)
                    .offset(x: width * clampedPosition - markerSize / 2)

                // End zones
                UnevenRoundedRectangle(
                    topLeadingRadius: 4, bottomLeadingRadius: 4,
                    bottomTrailingRadius: 0, topTrailingRadius: 0
                )
                .fill(Color.red.opacity(0.25))
                .frame(width: 8, height: height)

                UnevenRoundedRectangle(
                    topLeadingRadius: 0, bottomLeadingRadius: 0,
                    bottomTrailingRadius: 4, topTrailingRadius: 4
                )
                .fill(Color.blue.opacity(0.25))
                .frame(width: 8, height: height)
                .offset(x: width - 8)
            }
        }
    }
}
