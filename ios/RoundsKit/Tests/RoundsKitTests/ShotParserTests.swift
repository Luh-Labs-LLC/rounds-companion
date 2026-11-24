import Testing
@testable import RoundsKit

struct ShotParserTests {
    @Test func ironWithYardSuffix() {
        #expect(ShotParser.parse("7i 162y") == ShotRecord(club: .iron(7), distanceYards: 162))
    }

    @Test func wedgeWithBareNumber() {
        #expect(ShotParser.parse("PW 95") == ShotRecord(club: .pitchingWedge, distanceYards: 95))
    }

    @Test func driverWithDirection() {
        #expect(
            ShotParser.parse("driver 240 left")
                == ShotRecord(club: .driver, distanceYards: 240, missDirection: .left)
        )
    }

    @Test func fullSentenceKeepsUnknownWordsAsNotes() {
        #expect(
            ShotParser.parse("7i 162y pushed right, greenside bunker")
                == ShotRecord(
                    club: .iron(7),
                    distanceYards: 162,
                    outcome: .bunker,
                    missDirection: .right,
                    notes: "pushed greenside"
                )
        )
    }

    @Test func hyphenatedWoodAndYardsWord() {
        #expect(
            ShotParser.parse("3-wood 225 yds fairway")
                == ShotRecord(club: .wood(3), distanceYards: 225, outcome: .fairway)
        )
    }

    @Test func spelledOutIron() {
        #expect(ShotParser.parse("7 iron 150") == ShotRecord(club: .iron(7), distanceYards: 150))
    }

    @Test func degreeWedge() {
        #expect(
            ShotParser.parse("56° 40 short")
                == ShotRecord(club: .wedge(degrees: 56), distanceYards: 40, missDirection: .short)
        )
    }

    @Test func lieFromOutOfTheBunker() {
        #expect(
            ShotParser.parse("sand wedge out of the bunker 15 yards to the green")
                == ShotRecord(club: .sandWedge, distanceYards: 15, outcome: .green, lie: .bunker)
        )
    }

    @Test func lieOffTheTee() {
        #expect(
            ShotParser.parse("off the tee driver 280 fairway")
                == ShotRecord(club: .driver, distanceYards: 280, outcome: .fairway, lie: .tee)
        )
    }

    @Test func puttFeetAreNotYards() {
        #expect(
            ShotParser.parse("putter 12 ft holed")
                == ShotRecord(club: .putter, outcome: .holed, notes: "12 ft")
        )
    }

    @Test func outOfBounds() {
        #expect(
            ShotParser.parse("driver 250 ob right")
                == ShotRecord(club: .driver, distanceYards: 250, outcome: .outOfBounds, missDirection: .right)
        )
        #expect(ShotParser.parse("driver out of bounds")?.outcome == .outOfBounds)
    }

    @Test func implausibleDistanceGoesToNotes() {
        #expect(ShotParser.parse("7 iron 600") == ShotRecord(club: .iron(7), notes: "600"))
    }

    @Test func noClubMeansNoRecord() {
        #expect(ShotParser.parse("nice swing") == nil)
        #expect(ShotParser.parse("") == nil)
        #expect(ShotParser.parse("162 yards left") == nil)
    }

    @Test func parsedRecordsArePlausible() {
        for text in ["7i 162y", "PW 95", "driver 240 left", "56° 40 short", "putter 12 ft holed"] {
            let record = ShotParser.parse(text)
            #expect(record?.isPlausible == true, "\(text)")
        }
    }

    @Test func implausibleRecordsAreRejected() {
        #expect(!ShotRecord(club: .iron(12)).isPlausible)
        #expect(!ShotRecord(club: .wood(1)).isPlausible)
        #expect(!ShotRecord(club: .wedge(degrees: 80)).isPlausible)
        #expect(!ShotRecord(club: .driver, distanceYards: 900).isPlausible)
        #expect(!ShotRecord(club: .putter, distanceYards: 150).isPlausible)
        #expect(!ShotRecord(club: .driver, distanceYards: 0).isPlausible)
    }

    @Test func clubShortNames() {
        #expect(Club.iron(7).shortName == "7i")
        #expect(Club.wood(3).shortName == "3W")
        #expect(Club.wedge(degrees: 56).shortName == "56°")
    }
}

struct ShotDisplayTests {
    @Test func summaryListsRecordedFieldsOnly() {
        #expect(ShotRecord(club: .iron(7), distanceYards: 162, outcome: .bunker, missDirection: .right).summary
            == "7i · 162 y · right · bunker")
        #expect(ShotRecord(club: .putter, outcome: .holed).summary == "Putter · holed")
        #expect(ShotRecord(club: .driver, outcome: .outOfBounds, lie: .tee).summary == "Driver · OB · from tee")
    }
}
