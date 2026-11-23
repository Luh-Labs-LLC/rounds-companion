import Testing
@testable import RoundsKit

struct RoundStatsTests {
    // Par 4: fairway, green in two, two putts. Par 4.
    let parFour = HoleScore(number: 1, par: 4, shots: [
        ShotRecord(club: .driver, distanceYards: 250, outcome: .fairway),
        ShotRecord(club: .iron(7), distanceYards: 150, outcome: .green),
        ShotRecord(club: .putter),
        ShotRecord(club: .putter, outcome: .holed),
    ])

    // Par 3: bunker right, up and down. Par 3, green missed.
    let parThree = HoleScore(number: 2, par: 3, shots: [
        ShotRecord(club: .iron(6), distanceYards: 170, outcome: .bunker, missDirection: .right),
        ShotRecord(club: .sandWedge, distanceYards: 15, outcome: .green, lie: .bunker),
        ShotRecord(club: .putter, outcome: .holed),
    ])

    // Par 5: tee shot in the water (one penalty), on in four, two putts. Six.
    let parFive = HoleScore(number: 3, par: 5, shots: [
        ShotRecord(club: .driver, distanceYards: 240, outcome: .water, missDirection: .left),
        ShotRecord(club: .wood(3), distanceYards: 210, outcome: .rough),
        ShotRecord(club: .pitchingWedge, distanceYards: 100, outcome: .green),
        ShotRecord(club: .putter),
        ShotRecord(club: .putter, outcome: .holed),
    ])

    // Nothing logged yet.
    let unplayed = HoleScore(number: 4, par: 4, shots: [])

    @Test func perHoleNumbers() {
        #expect(parFour.strokes == 4)
        #expect(parFour.greenInRegulation)
        #expect(parFour.hitFairway)
        #expect(parFour.putts == 2)

        #expect(parThree.strokes == 3)
        #expect(!parThree.greenInRegulation)
        #expect(!parThree.isFairwayOpportunity)

        #expect(parFive.penaltyStrokes == 1)
        #expect(parFive.strokes == 6)
        #expect(!parFive.greenInRegulation)
        #expect(parFive.isFairwayOpportunity)
        #expect(!parFive.hitFairway)
    }

    @Test func roundTotals() {
        let stats = RoundStats(holes: [parFour, parThree, parFive, unplayed])
        #expect(stats.holesPlayed == 3)
        #expect(stats.par == 12)
        #expect(stats.strokes == 13)
        #expect(stats.scoreToPar == 1)
        #expect(stats.penaltyStrokes == 1)
        #expect(stats.fairwaysHit == 1)
        #expect(stats.fairwayOpportunities == 2)
        #expect(stats.greensInRegulation == 1)
        #expect(stats.putts == 5)
        #expect(stats.missesByDirection == [.right: 1, .left: 1])
    }

    @Test func teeShotWithoutOutcomeIsNotAFairwayOpportunity() {
        let hole = HoleScore(number: 5, par: 4, shots: [ShotRecord(club: .driver, distanceYards: 250)])
        #expect(!hole.isFairwayOpportunity)
        #expect(!hole.greenInRegulation)
    }

    @Test func chipInCountsAsReachingTheGreen() {
        let hole = HoleScore(number: 6, par: 4, shots: [
            ShotRecord(club: .driver, outcome: .fairway),
            ShotRecord(club: .pitchingWedge, outcome: .holed),
        ])
        #expect(hole.greenInRegulation)
        #expect(hole.strokes == 2)
    }

    @Test func emptyRound() {
        let stats = RoundStats(holes: [])
        #expect(stats.holesPlayed == 0)
        #expect(stats.strokes == 0)
        #expect(stats.missesByDirection.isEmpty)
    }
}
