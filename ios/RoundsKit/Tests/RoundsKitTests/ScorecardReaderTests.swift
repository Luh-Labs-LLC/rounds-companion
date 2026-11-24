import Testing
@testable import RoundsKit

struct ScorecardReaderTests {
    @Test func readsNineHoles() {
        #expect(ScorecardReader.pars(from: "PARS: 4 4 3 5 4 4 3 4 5") == [4, 4, 3, 5, 4, 4, 3, 4, 5])
    }

    @Test func readsEighteenWithUnknowns() {
        let answer = "PARS: 4 5 3 4 4 ? 4 3 5 4 4 3 5 4 4 3 ? 5"
        let pars = ScorecardReader.pars(from: answer)
        #expect(pars?.count == 18)
        #expect(pars?[5] == .some(nil))
        #expect(pars?[16] == .some(nil))
        #expect(pars?[0] == 4)
    }

    @Test func dropsTotalsAndFormatting() {
        #expect(ScorecardReader.pars(from: "**PARS:** 4, 4, 3, 5, 4, 4, 3, 4, 5 | 36")
            == [4, 4, 3, 5, 4, 4, 3, 4, 5])
    }

    @Test func findsTheParsLineAmongChatter() {
        let answer = "Here is what I can read.\nPARS: 5 4 3 4 4 4 3 5 4\nHope that helps!"
        #expect(ScorecardReader.pars(from: answer) == [5, 4, 3, 4, 4, 4, 3, 5, 4])
    }

    @Test func rejectsWrongCounts() {
        #expect(ScorecardReader.pars(from: "PARS: 4 4 3") == nil)
        #expect(ScorecardReader.pars(from: "PARS: 4 4 3 5 4 4 3 4 5 4") == nil)
    }

    @Test func rejectsMostlyUnreadable() {
        #expect(ScorecardReader.pars(from: "PARS: ? ? ? ? ? ? 4 4 4") == nil)
    }

    @Test func rejectsNonAnswers() {
        #expect(ScorecardReader.pars(from: "I can't see a scorecard in this photo.") == nil)
        #expect(ScorecardReader.pars(from: "") == nil)
    }

    @Test func misreadSmallNumbersBecomeUnknown() {
        #expect(ScorecardReader.pars(from: "PARS: 4 4 2 5 4 4 3 4 5")?[2] == .some(nil))
    }
}
