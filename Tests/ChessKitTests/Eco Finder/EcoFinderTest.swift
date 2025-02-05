//
//  EcoFinderTest.swift
//  ChessKit
//
//  Created by Amir Zucker on 03/02/2025.
//

import Testing
@testable import ChessKit

@Suite("Eco Finder Tests")
struct EcoFinderTest {
    let bongcloudName = "Bongcloud Attack"
    let bongcloudCode = "C20"
    let bongcloudPGNString = "1. e4 e5 2. Ke2"
    let bongcloudPGNString2 = "1. e4 e5 2. Ke2 Nf6"
    let bongcloudFENString = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPPKPPP/RNBQ1BNR b kq -"
    let bongcloudFENString2 = "rnbqkb1r/pppp1ppp/5n2/4p3/4P3/8/PPPPKPPP/RNBQ1BNR w kq -"
    let bongcloudFENStringWithMoves = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPPKPPP/RNBQ1BNR b kq - 1 2"
    
    let kingsPawnGameName = "King's Pawn Game"
    let kingsPawnGameCode = "C20"
    let kingsPawnGamePGNString = "1. e4 e5"
    let kingsPawnGameFENString = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -"
    
    let fenString = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    
    let movesForBongcloud: [Move] = [
        Move(result: .move, piece: Piece(.pawn, color: .white, square: .e2), start: .e2, end: .e4),
        Move(result: .move, piece: Piece(.pawn, color: .black, square: .e7), start: .e7, end: .e5),
        Move(result: .move, piece: Piece(.king, color: .white, square: .e1), start: .e1, end: .e2)
    ]

    let ecoFinder: EcoFinder
    
    init() throws {
        self.ecoFinder = try EcoFinder()
    }
    
    //MARK: - Get FEN
    @Test
    func testFENGetEco_shouldFindKingsPawnGame() {
        let kingsPawnEco = ecoFinder.getEco(for: kingsPawnGameFENString, positionType: .FEN)
        
        #expect(kingsPawnEco != nil)
        #expect(kingsPawnEco?.ecoCode == kingsPawnGameCode)
        #expect(kingsPawnEco?.name == kingsPawnGameName)
        #expect(kingsPawnEco?.moves == kingsPawnGamePGNString)
    }
    
    @Test
    func testFENGetEco_shouldFindBongCloudAttack() {
        let bongcloudEco = ecoFinder.getEco(for: bongcloudFENString, positionType: .FEN)
        
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco?.ecoCode == bongcloudCode)
        #expect(bongcloudEco?.name == bongcloudName)
        #expect(bongcloudEco?.moves == bongcloudPGNString)
    }
    @Test
    func testFENWithMovesGetEco_shouldFindBongCloudAttack() {
        let bongcloudEco = ecoFinder.getEco(for: bongcloudFENStringWithMoves, positionType: .FEN)
        
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco?.ecoCode == bongcloudCode)
        #expect(bongcloudEco?.name == bongcloudName)
        #expect(bongcloudEco?.moves == bongcloudPGNString)
    }
    
    @Test
    func testFENGetEco_shouldNotFindBongCloudAttack() {
        let noEco = ecoFinder.getEco(for: bongcloudFENString2, positionType: .FEN)
        
        #expect(noEco == nil)
    }
    
    @Test
    func testFENGetEco_shouldNotFindEco() {
        let noEco = ecoFinder.getEco(for: fenString, positionType: .FEN)
        
        #expect(noEco == nil)
    }
    
    //MARK: - Get PGN
    @Test
    func testPGNGetEco_shouldFindKingsPawnGame() {
        let kingsPawnEco = ecoFinder.getEco(for: kingsPawnGamePGNString, positionType: .PGN)
        
        #expect(kingsPawnEco != nil)
        #expect(kingsPawnEco?.ecoCode == kingsPawnGameCode)
        #expect(kingsPawnEco?.name == kingsPawnGameName)
        #expect(kingsPawnEco?.moves == kingsPawnGamePGNString)
    }
    
    @Test
    func testPGNWithAnnotationsGetEco_shouldFindKingsPawnGame() {
        let pgn = """
        [Event "Casual game"]
        [Date "2025.02.05"]
        [White "ChessKit"]
        [Black "ChessKit"]
        [Result "1-0"]
        [WhiteElo "?"]
        [BlackElo "1500"]
        [Variant "Standard"]
        [TimeControl "-"]
        [ECO "C20"]
        [Opening "King's Pawn Game"]
        [Termination "Normal"]

        1. e4 e5 { C20 King's Pawn Game } { Black resigns. } 1-0
        """
        let kingsPawnEco = ecoFinder.getEco(for: pgn, positionType: .PGN)
        
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

        let vantKruijsOpeningEco = ecoFinder.getEco(for: vantKruijsOpeningPGNString, positionType: .PGN)
        
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

        let gentGambitEco = ecoFinder.getEco(for: gentGambitPGNString, positionType: .PGN)
        
        #expect(gentGambitEco != nil)
        #expect(gentGambitEco?.ecoCode == gentGambitCode)
        #expect(gentGambitEco?.name == gentGambitName)
        #expect(gentGambitEco?.moves == gentGambitPGNString)
    }
    
    @Test
    func testPGNGetEco_shouldNotFindEco() {
        let noEco = ecoFinder.getEco(for: fenString, positionType: .PGN)
        
        #expect(noEco == nil)
    }
    
    //MARK: - Search PGN
    @Test
    func testPGNSearchFirstMove_shouldFindKingsPawnGame() throws {
        let kingsPawnGameCodeFirstMove = "B00"
        let kingsPawnGamePGNStringFirstMove = "1. e4"
        
        let kingsPawnEco = try ecoFinder.searchEco(for: kingsPawnGamePGNStringFirstMove)
        
        #expect(kingsPawnEco.ecoCode == kingsPawnGameCodeFirstMove)
        #expect(kingsPawnEco.name == kingsPawnGameName)
        #expect(kingsPawnEco.moves == kingsPawnGamePGNStringFirstMove)
    }
    
    @Test
    func testPGNSearch_shouldFindKingsPawnGame() throws {
        let kingsPawnEco = try ecoFinder.searchEco(for: kingsPawnGamePGNString)
        
        #expect(kingsPawnEco.ecoCode == kingsPawnGameCode)
        #expect(kingsPawnEco.name == kingsPawnGameName)
        #expect(kingsPawnEco.moves == kingsPawnGamePGNString)
    }
    
    @Test
    func testPGNSearch_shouldFindBongcloud() throws {
        let bongcloudEco = try ecoFinder.searchEco(for: bongcloudPGNString)
        
        #expect(bongcloudEco.ecoCode == bongcloudCode)
        #expect(bongcloudEco.name == bongcloudName)
        #expect(bongcloudEco.moves == bongcloudPGNString)
    }
    
    @Test
    func testPGNSearchAdvancedMove_shouldFindBongcloud() throws {
        let bongcloudEco = try ecoFinder.searchEco(for: bongcloudPGNString2)
        
        #expect(bongcloudEco.ecoCode == bongcloudCode)
        #expect(bongcloudEco.name == bongcloudName)
        #expect(bongcloudEco.moves == bongcloudPGNString)
    }
    
    @Test
    func testPGNSearch_shouldThrowEcoNotFound() throws {
        #expect(throws: EcoFinderError.EcoNotFound, performing: {
            try ecoFinder.searchEco(for: fenString)
        })
    }
    
    //MARK: - Get Moves
    @Test
    func testMovesGetEco_shouldFindBongcloud() {
        let bongcloudEco = ecoFinder.getEco(for: movesForBongcloud)
        
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco?.ecoCode == bongcloudCode)
        #expect(bongcloudEco?.name == bongcloudName)
        #expect(bongcloudEco?.moves == bongcloudPGNString)
    }
    
    @Test
    func testMovesGetEco_shouldNotFindEco() {
        let moves = [Move(result: .move, piece: Piece(.bishop, color: .white, square: .c1), start: .c1, end: .e3)]
        let noEco = ecoFinder.getEco(for: moves)
        
        #expect(noEco == nil)
    }
    
    @Test
    func testMovesGetEcoAdvanceMove_shouldNotFindEco() {
        var moves = movesForBongcloud
        moves.append(Move(result: .move, piece: Piece(.king, color: .black, square: .e8), start: .e8, end: .e7))
        
        let bongcloudEco = ecoFinder.getEco(for: moves)
        
        #expect(bongcloudEco == nil)
    }
    
    //MARK: - Search Moves
    @Test
    func testMovesSearchEco_shouldFindBongcloud() throws {
        let bongcloudEco = try ecoFinder.searchEco(for: movesForBongcloud)
        
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco.ecoCode == bongcloudCode)
        #expect(bongcloudEco.name == bongcloudName)
        #expect(bongcloudEco.moves == bongcloudPGNString)
    }
    
    @Test
    func testMovesSearchEcoAdvanceMove_shouldFindBongcloud() throws {
        var moves = movesForBongcloud
        moves.append(Move(result: .move, piece: Piece(.king, color: .black, square: .e8), start: .e8, end: .e7))
        
        let bongcloudEco = try ecoFinder.searchEco(for: moves)
        
        #expect(bongcloudEco.ecoCode == bongcloudCode)
        #expect(bongcloudEco.name == bongcloudName)
        #expect(bongcloudEco.moves == bongcloudPGNString)
    }
    
    @Test
    func testMovesSearchEcoEmptyMoves_shouldNotFindEco() {
        #expect(throws: EcoFinderError.EcoNotFound, performing: {
            try ecoFinder.searchEco(for: [])
        })
    }
    
    //MARK: Get Game
    @Test
    func testGameFromPGNGetEco_shouldFindBongcloud() {
        let game = Game(pgn: bongcloudPGNString)!
        let bongcloudEco = ecoFinder.getEco(for: game)
                
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco?.ecoCode == bongcloudCode)
        #expect(bongcloudEco?.name == bongcloudName)
        #expect(bongcloudEco?.moves == bongcloudPGNString)
    }
    
    @Test
    func testGameFromPGNAdvanceMoveGetEco_shouldFindBongcloud() {
        var game = Game(pgn: bongcloudPGNString)!
        let move = Move(result: .move, piece: Piece(.knight, color: .black, square: .g8), start: .g8, end: .f6)
        game.make(move: move, from: game.moves.startIndex)
        let bongcloudEco = ecoFinder.getEco(for: game)
                
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco?.ecoCode == bongcloudCode)
        #expect(bongcloudEco?.name == bongcloudName)
        #expect(bongcloudEco?.moves == bongcloudPGNString)
    }
    
    @Test
    func testGameGetEco_shouldNotFindEco() {
        let game = Game()
        let noEco = ecoFinder.getEco(for: game)
        
        #expect(noEco == nil)
    }
    
    //MARK: - Search Game
    @Test
    func testGameFromPGNSearchEco_shouldFindBongcloud() {
        let game = Game(pgn: bongcloudPGNString)!
        let bongcloudEco = try? ecoFinder.searchEco(for: game)
                
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco?.ecoCode == bongcloudCode)
        #expect(bongcloudEco?.name == bongcloudName)
        #expect(bongcloudEco?.moves == bongcloudPGNString)
    }
    
    @Test
    func testGameFromPGNAdvanceMoveSearchEco_shouldFindBongcloud() {
        var game = Game(pgn: bongcloudPGNString)!
        let move = Move(result: .move, piece: Piece(.knight, color: .black, square: .g8), start: .g8, end: .f6)
        game.make(move: move, from: game.moves.endIndex)
        let bongcloudEco = try? ecoFinder.searchEco(for: game)
                
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco?.ecoCode == bongcloudCode)
        #expect(bongcloudEco?.name == bongcloudName)
        #expect(bongcloudEco?.moves == bongcloudPGNString)
    }
    
    @Test
    func testGameFromFENSearchEco_shouldFindBongcloud() {
        let position = Position(fen: bongcloudFENStringWithMoves)
        let game = Game(startingWith: position!)
        let bongcloudEco = ecoFinder.getEco(for: game)
                
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco?.ecoCode == bongcloudCode)
        #expect(bongcloudEco?.name == bongcloudName)
        #expect(bongcloudEco?.moves == bongcloudPGNString)
    }
    
    @Test
    func testGameFromFENAdvanceMoveSearchEco_shouldFindBongcloud() {
        let position = Position(fen: bongcloudFENStringWithMoves)
        var game = Game(startingWith: position!)
        let moves = ["Nf6", "Ke1"]
        game.make(moves: moves, from: game.moves.startIndex)
        
        let bongcloudEco = ecoFinder.getEco(for: game)
                
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco?.ecoCode == bongcloudCode)
        #expect(bongcloudEco?.name == bongcloudName)
        #expect(bongcloudEco?.moves == bongcloudPGNString)
    }
    
    //MARK: - Get Position
    @Test
    func getPositionFromFEN_shouldFindBongCloudAttack() {
        let position = Position(fen: bongcloudFENStringWithMoves)
        let bongcloudEco = ecoFinder.getEco(for: position!)
                
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco?.ecoCode == bongcloudCode)
        #expect(bongcloudEco?.name == bongcloudName)
        #expect(bongcloudEco?.moves == bongcloudPGNString)
    }
        
    @Test
    func getPositionFromGame_shouldFindBongCloudAttack() {
        let game = Game(pgn: bongcloudPGNString)
        let endIndex = game!.moves.endIndex
        let position = game!.positions[endIndex]!
        let bongcloudEco = ecoFinder.getEco(for: position)
                
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco?.ecoCode == bongcloudCode)
        #expect(bongcloudEco?.name == bongcloudName)
        #expect(bongcloudEco?.moves == bongcloudPGNString)
    }
    
    //MARK: - Get Name
    @Test
    func testNameGetEco_shouldFindKingsPawnGame() {
        let kingsPawnEco = ecoFinder.getEco(by: kingsPawnGameName)
        
        #expect(kingsPawnEco != nil)
        #expect(kingsPawnEco?.ecoCode == kingsPawnGameCode)
        #expect(kingsPawnEco?.name == kingsPawnGameName)
        #expect(kingsPawnEco?.moves == kingsPawnGamePGNString)
    }
    
    @Test
    func testNameGetEco_shouldFindBongCloud() {
        let bongcloudEco = ecoFinder.getEco(by: bongcloudName)
        
        #expect(bongcloudEco != nil)
        #expect(bongcloudEco?.ecoCode == bongcloudCode)
        #expect(bongcloudEco?.name == bongcloudName)
        #expect(bongcloudEco?.moves == bongcloudPGNString)
    }
    
    func testNameGetEco_shouldNotFindEco() {
        let noEco = ecoFinder.getEco(by: kingsPawnGameName + ":")
        
        #expect(noEco == nil)
    }
}
