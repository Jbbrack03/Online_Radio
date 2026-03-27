import SwiftUI

/// Football field position showing down, distance, and yard line.
struct FootballFieldView: View {
    let situation: FootballSituation
    var compact: Bool = false

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
            // Down and distance
            Text(situation.fieldPosition)
                .font(.subheadline.bold())

            // Field position bar
            fieldBar
                .frame(height: 24)

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
                // Field background
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.3), .green.opacity(0.5), .green.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                // Yard line markers (every 10 yards)
                ForEach(1..<10, id: \.self) { i in
                    let x = width * CGFloat(i) / 10.0
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 1, height: height)
                        .offset(x: x)
                }

                // 50 yard line
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 2, height: height)
                    .offset(x: width / 2)

                // Ball position marker
                let yardPosition = CGFloat(situation.yardLine) / 100.0
                Circle()
                    .fill(Color.orange)
                    .frame(width: 12, height: 12)
                    .shadow(color: .orange.opacity(0.5), radius: 3)
                    .offset(x: width * yardPosition - 6)

                // End zones
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.red.opacity(0.3))
                    .frame(width: 8, height: height)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 8, height: height)
                    .offset(x: width - 8)
            }
        }
    }
}
