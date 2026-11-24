import Testing
@testable import RoundsKit

struct ShotMergeTests {
    @Test func golferWordsWinOverModel() {
        let words = ShotRecord(club: .iron(7), distanceYards: 162)
        let model = ShotRecord(club: .iron(6), distanceYards: 170, outcome: .bunker, missDirection: .right)
        #expect(
            ShotMerge.merge(fromWords: words, fromModel: model)
                == ShotRecord(club: .iron(7), distanceYards: 162, outcome: .bunker, missDirection: .right)
        )
    }

    @Test func modelFillsGapsOnly() {
        let words = ShotRecord(club: .driver, notes: "smoked")
        let model = ShotRecord(club: .driver, distanceYards: 260, outcome: .fairway, notes: "model chatter")
        #expect(
            ShotMerge.merge(fromWords: words, fromModel: model)
                == ShotRecord(club: .driver, distanceYards: 260, outcome: .fairway, notes: "smoked")
        )
    }

    @Test func modelAloneWhenWordsHaveNoClub() {
        let model = ShotRecord(club: .iron(7), distanceYards: 160, missDirection: .right)
        #expect(ShotMerge.merge(fromWords: nil, fromModel: model) == model)
    }

    @Test func implausibleModelAnswerIsIgnored() {
        let words = ShotRecord(club: .pitchingWedge, distanceYards: 95)
        let bad = ShotRecord(club: .iron(14), distanceYards: 900)
        #expect(ShotMerge.merge(fromWords: words, fromModel: bad) == words)
        #expect(ShotMerge.merge(fromWords: nil, fromModel: bad) == nil)
    }

    @Test func nothingUsableMeansNoShot() {
        #expect(ShotMerge.merge(fromWords: nil, fromModel: nil) == nil)
    }

    @Test func modelShorthandIsParsed() {
        #expect(
            ShotMerge.parseModelShorthand("7i 160 right bunker")
                == ShotRecord(club: .iron(7), distanceYards: 160, outcome: .bunker, missDirection: .right)
        )
    }

    @Test func modelShorthandUsesFirstLineAndDropsChatter() {
        let text = "`driver 250 fairway` nice\nAlso: 7i 150 green"
        #expect(ShotMerge.parseModelShorthand(text) == ShotRecord(club: .driver, distanceYards: 250, outcome: .fairway))
    }

    @Test func malformedModelAnswerIsRejected() {
        #expect(ShotMerge.parseModelShorthand("I'm not sure what club you used.") == nil)
        #expect(ShotMerge.parseModelShorthand("") == nil)
    }

    @Test func endToEndSpokenStyleInput() {
        // The golfer's words alone give club and direction; the model's rewrite adds the rest.
        let spoken = "hit my 7 iron, pushed it right into the trap by the green"
        let words = ShotParser.parse(spoken)
        #expect(words?.club == .iron(7))
        #expect(words?.missDirection == .right)
        let model = ShotMerge.parseModelShorthand("7i right bunker")
        let merged = ShotMerge.merge(fromWords: words, fromModel: model)
        #expect(merged?.club == .iron(7))
        #expect(merged?.missDirection == .right)
        #expect(merged?.outcome == .bunker)
    }
}
