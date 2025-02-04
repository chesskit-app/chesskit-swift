//
//  EcoFinderTest.swift
//  ChessKit
//
//  Created by Amir Zucker on 03/02/2025.
//

import Testing
@testable import ChessKit

@Suite(.serialized)
struct EcoFinderTest {
    let bongcloudName = "Bongcloud Attack"
    let bongcloudCode = "C20"
    let bongcloudPGNString = "1. e4 e5 2. Ke2"
    let bongcloudPGNString2 = "1. e4 e5 2. Ke2 Nf6"
    
    let kingsPawnGameName = "King's Pawn Game"
    let kingsPawnGameCode = "C20"
    let kingsPawnGamePGNString = "1. e4 e5"
    
    let fenString = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    
    let movesForBongcloud: [Move] = [
        Move(result: .move, piece: Piece(.pawn, color: .white, square: .e2), start: .e2, end: .e4),
        Move(result: .move, piece: Piece(.pawn, color: .black, square: .e7), start: .e7, end: .e5),
        Move(result: .move, piece: Piece(.king, color: .white, square: .e1), start: .e1, end: .e2)
    ]

    let ecoFinder: EcoFinder
    
    init() async throws {
        self.ecoFinder = try await EcoFinder()
    }
    
    //MARK: - Get PGN
    @Test
    func testPGNGetEco_shouldFindKingsPawnGame() {
        let kingsPawnEco = ecoFinder.getEco(pgn: kingsPawnGamePGNString)
        
        #expect(kingsPawnEco != nil)
        #expect(kingsPawnEco?.ecoCode == kingsPawnGameCode)
        #expect(kingsPawnEco?.name == kingsPawnGameName)
        #expect(kingsPawnEco?.moves == kingsPawnGamePGNString)
    }
    
    @Test
    func testPGNGetFirstEcoInFile_shouldFindVantKruijsOpening() {
        let vantKruijsOpeningName = "Van't Kruijs Opening"
        let vantKruijsOpeningCode = "A00"
        let vantKruijsOpeningPGNString = "1. e3"

        let vantKruijsOpeningEco = ecoFinder.getEco(pgn: vantKruijsOpeningPGNString)
        
        #expect(vantKruijsOpeningEco != nil)
        #expect(vantKruijsOpeningEco?.ecoCode == vantKruijsOpeningCode)
        #expect(vantKruijsOpeningEco?.name == vantKruijsOpeningName)
        #expect(vantKruijsOpeningEco?.moves == vantKruijsOpeningPGNString)
    }
    
    @Test
    func testPGNGetLastEcoInFile_shouldFindGentGambit() {
        let gentGambitName = "Amar Opening: Paris Gambit, Gent Gambit"
        let gentGambitCode = "A00"
        let gentGambitPGNString = "1. Nh3 d5 2. g3 e5 3. f4 Bxh3 4. Bxh3 exf4 5. O-O fxg3 6. hxg3"

        let gentGambitEco = ecoFinder.getEco(pgn: gentGambitPGNString)
        
        #expect(gentGambitEco != nil)
        #expect(gentGambitEco?.ecoCode == gentGambitCode)
        #expect(gentGambitEco?.name == gentGambitName)
        #expect(gentGambitEco?.moves == gentGambitPGNString)
    }
    
    @Test
    func testPGNGetEco_shouldNotFindEco() {
        let kingsPawnEco = ecoFinder.getEco(pgn: fenString)
        
        #expect(kingsPawnEco == nil)
    }
    
    //MARK: - Search PGN
    @Test
    func testPGNSearch_shouldFindKingsPawnGame() throws {
        let kingsPawnGameCodeFirstMove = "B00"
        let kingsPawnGamePGNStringFirstMove = "1. e4"
        
        let kingsPawnEco = try ecoFinder.searchEco(pgn: kingsPawnGamePGNStringFirstMove)
        
        #expect(kingsPawnEco.ecoCode == kingsPawnGameCodeFirstMove)
        #expect(kingsPawnEco.name == kingsPawnGameName)
        #expect(kingsPawnEco.moves == kingsPawnGamePGNStringFirstMove)
    }
    
    @Test
    func testPGNSearch_shouldFindKingsPawnGame2() throws {
        let kingsPawnEco = try ecoFinder.searchEco(pgn: kingsPawnGamePGNString)
        
        #expect(kingsPawnEco.ecoCode == kingsPawnGameCode)
        #expect(kingsPawnEco.name == kingsPawnGameName)
        #expect(kingsPawnEco.moves == kingsPawnGamePGNString)
    }
    
    @Test
    func testPGNSearch_shouldFindBongcloud() throws {
        let bongcloudEco = try ecoFinder.searchEco(pgn: bongcloudPGNString)
        
        #expect(bongcloudEco.ecoCode == bongcloudCode)
        #expect(bongcloudEco.name == bongcloudName)
        #expect(bongcloudEco.moves == bongcloudPGNString)
    }
    
    @Test
    func testPGNSearchAdvancedMove_shouldFindBongcloud() throws {
        let bongcloudEco = try ecoFinder.searchEco(pgn: bongcloudPGNString2)
        
        #expect(bongcloudEco.ecoCode == bongcloudCode)
        #expect(bongcloudEco.name == bongcloudName)
        #expect(bongcloudEco.moves == bongcloudPGNString)
    }
    
    @Test
    func testPGNSearch_shouldThrowEcoNotFound() throws {
        #expect(throws: EcoFinderError.EcoNotFound(fenString), performing: {
            try ecoFinder.searchEco(pgn: fenString)
        })
    }
    
    //MARK: - Get Moves
    @Test
    func testMovesGetEco_shouldFindBongcloud() {
        let bongcloudEco = ecoFinder.getEco(moves: movesForBongcloud)
        
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco?.ecoCode == bongcloudCode)
        #expect(bongcloudEco?.name == bongcloudName)
        #expect(bongcloudEco?.moves == bongcloudPGNString)
    }
    
    @Test
    func testMovesGetEco_shouldNotFindEco() {
        let moves = [Move(result: .move, piece: Piece(.bishop, color: .white, square: .c1), start: .c1, end: .e3)]
        let randomEco = ecoFinder.getEco(moves: moves)
        
        #expect(randomEco == nil)
    }
    
    @Test
    func testMovesGetEcoAdvanceMove_shouldNotFindEco() {
        var moves = movesForBongcloud
        moves.append(Move(result: .move, piece: Piece(.king, color: .black, square: .e8), start: .e8, end: .e7))
        
        let bongcloudEco = ecoFinder.getEco(moves: moves)
        
        #expect(bongcloudEco == nil)
    }
    
    //MARK: - Search Moves
    @Test
    func testMovesSearchEco_shouldFindBongcloud() throws {
        let bongcloudEco = try ecoFinder.searchEco(moves: movesForBongcloud)
        
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco.ecoCode == bongcloudCode)
        #expect(bongcloudEco.name == bongcloudName)
        #expect(bongcloudEco.moves == bongcloudPGNString)
    }
    
    @Test
    func testMovesSearchEcoAdvanceMove_shouldFindBongcloud() throws {
        var moves = movesForBongcloud
        moves.append(Move(result: .move, piece: Piece(.king, color: .black, square: .e8), start: .e8, end: .e7))
        
        let bongcloudEco = try ecoFinder.searchEco(moves: moves)
        
        #expect(bongcloudEco.ecoCode == bongcloudCode)
        #expect(bongcloudEco.name == bongcloudName)
        #expect(bongcloudEco.moves == bongcloudPGNString)
    }
    
    @Test
    func testMovesSearchEcoEmptyMoves_shouldNotFindEco() {
        #expect(throws: EcoFinderError.EcoNotFound(""), performing: {
            try ecoFinder.searchEco(moves: [])
        })
    }
    
    //MARK: - Get Name
    @Test
    func testNameGetEco_shouldFindKingsPawnGame() {
        let kingsPawnEco = ecoFinder.getEco(ecoName: kingsPawnGameName)
        
        #expect(kingsPawnEco != nil)
        #expect(kingsPawnEco?.ecoCode == kingsPawnGameCode)
        #expect(kingsPawnEco?.name == kingsPawnGameName)
        #expect(kingsPawnEco?.moves == kingsPawnGamePGNString)
    }
    
    @Test
    func testNameGetEco_shouldFindBongCloud() {
        let bongcloudEco = ecoFinder.getEco(ecoName: bongcloudName)
        
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco?.ecoCode == bongcloudCode)
        #expect(bongcloudEco?.name == bongcloudName)
        #expect(bongcloudEco?.moves == bongcloudPGNString)
    }
    
    func testNameGetEco_shouldNotFindEco() {
        let kingsPawnEco = ecoFinder.getEco(ecoName: kingsPawnGameName + ":")
        
        #expect(kingsPawnEco == nil)
    }
}
