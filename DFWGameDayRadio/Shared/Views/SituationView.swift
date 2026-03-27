import SwiftUI

/// Dispatches to the correct sport-specific situation view.
struct SituationView: View {
    let situation: GameSituation
    let homeTeam: String
    let awayTeam: String
    var compact: Bool = false

    var body: some View {
        switch situation {
        case .baseball(let s):
            BaseballDiamondView(situation: s, compact: compact)
        case .football(let s):
            FootballFieldView(situation: s, compact: compact)
        case .hockey(let s):
            HockeyRinkView(situation: s, compact: compact)
        case .basketball(let s):
            BasketballCourtView(situation: s, homeTeam: homeTeam, awayTeam: awayTeam, compact: compact)
        }
    }
}
