import Testing
@testable import RoundsKit

struct CaddieFactsTests {
    let holes = [
        HoleScore(number: 1, par: 4, shots: [
            ShotRecord(club: .driver, outcome: .rough, missDirection: .right),
            ShotRecord(club: .iron(7), outcome: .green),
            ShotRecord(club: .putter),
            ShotRecord(club: .putter, outcome: .holed),
        ]),
        HoleScore(number: 2, par: 3, shots: [
            ShotRecord(club: .iron(6), outcome: .bunker, missDirection: .right),
            ShotRecord(club: .sandWedge, outcome: .green),
            ShotRecord(club: .putter, outcome: .holed),
        ]),
    ]

    @Test func factsComeFromComputedStats() {
        let facts = CaddieFacts.facts(for: holes)
        #expect(facts.contains("Holes played: 2"))
        #expect(facts.contains("Strokes: 7 against par 7 (even)"))
        #expect(facts.contains("Fairways hit: 0 of 1"))
        #expect(facts.contains("Greens in regulation: 1 of 2"))
        #expect(facts.contains("Putts: 3"))
        #expect(facts.contains("Tee shot misses: right 1"))
        #expect(facts.contains("Other full-shot misses: right 1"))
        #expect(facts.contains("Missed shots by club: Driver right, 6i right"))
    }

    @Test func answerWithKnownNumbersPasses() {
        let facts = CaddieFacts.facts(for: holes)
        #expect(CaddieFacts.answerUsesOnlyKnownNumbers(
            "Both misses went right, off the tee and with the 6 iron. Aim at the left half of greens; you have 3 putts over 2 holes.",
            facts: facts
        ))
    }

    @Test func answerWithInventedNumberFails() {
        let facts = CaddieFacts.facts(for: holes)
        #expect(!CaddieFacts.answerUsesOnlyKnownNumbers("You are losing 2.4 strokes to the field.", facts: facts))
        #expect(!CaddieFacts.answerUsesOnlyKnownNumbers("You've hit 80% of greens.", facts: facts))
    }

    @Test func numberExtraction() {
        #expect(CaddieFacts.numbers(in: "7i 162y, 3 of 4") == [7, 162, 3, 4])
        #expect(CaddieFacts.numbers(in: "no digits") == [])
    }

    @Test func emptyRoundFacts() {
        let facts = CaddieFacts.facts(for: [])
        #expect(facts.contains("Holes played: 0"))
        #expect(facts.contains("No misses by direction recorded"))
    }

    @Test func roundFactsListEachPlayedHole() {
        let facts = CaddieFacts.roundFacts(for: holes + [HoleScore(number: 3, par: 5, shots: [])])
        #expect(facts.contains("Hole 1, par 4: 4 strokes. Shots: Driver · right · rough; 7i · green; Putter; Putter · holed"))
        #expect(facts.contains("Hole 2, par 3: 3 strokes."))
        #expect(!facts.contains("Hole 3,"))
        #expect(CaddieFacts.answerUsesOnlyKnownNumbers("On hole 2 the 6i went right into the bunker.", facts: facts))
    }
}
