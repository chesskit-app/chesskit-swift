//
//  GameTests.swift
//  ChessKitTests
//

import XCTest
@testable import ChessKit

class GameTests: XCTestCase {
    
    func testMakeMoves() {
        let game = Game()
        game.make(moves: ["e4", "e5", "Nf3", "Nc6", "Bc4"])
        
        XCTAssertEqual(game.moves[.init(number: 1, color: .white, variation: 0)]?.san, "e4")
        XCTAssertEqual(game.moves[.init(number: 1, color: .black, variation: 0)]?.san, "e5")
        XCTAssertEqual(game.moves[.init(number: 2, color: .white, variation: 0)]?.san, "Nf3")
        XCTAssertEqual(game.moves[.init(number: 2, color: .black, variation: 0)]?.san, "Nc6")
        XCTAssertEqual(game.moves[.init(number: 3, color: .white, variation: 0)]?.san, "Bc4")
    }
    
    func testMoveVariations() {
        let game = Game()
        game.make(moves: ["e4", "e5", "Nf3", "Nc6", "Bc4"])
        
        // add 2. Nc3 ... variation to 2. Nf3
        let nf3Index = MoveTree.Index(number: 2, color: .white, variation: 0)
        game.make(moves: ["Nc3", "Nf6", "Bc4"], from: nf3Index.previous)
        
        let nc3Index = MoveTree.Index(number: 2, color: .white, variation: 1)
        
        XCTAssertEqual(game.moves[nf3Index]?.san, "Nf3")
        XCTAssertEqual(game.moves[nc3Index]?.san, "Nc3")
        
        // add 2... Nc6 ... variation to 2... Nf6
        let nf6Index = MoveTree.Index(number: 2, color: .black, variation: 1)
        game.make(moves: ["Nc6", "f4"], from: nf6Index.previous)
        
        let nc6Index = MoveTree.Index(number: 2, color: .black, variation: 2)
        
        XCTAssertEqual(game.moves[nf6Index]?.san, "Nf6")
        XCTAssertEqual(game.moves[nc6Index]?.san, "Nc6")

        XCTAssertEqual(
            game.moves.previousIndex(
                for: nc6Index
            ),
            nc3Index
        )

        // add another variation to 2... Nf6
        let nc6Index2 = MoveTree.Index(number: 2, color: .black, variation: 0)
        game.make(moves: ["f5", "exf5"], from: nc6Index2.previous)
        
        let f5Index = MoveTree.Index(number: 2, color: .black, variation: 3)
        
        XCTAssertEqual(game.moves[nc6Index2]?.san, "Nc6")
        XCTAssertEqual(game.moves[f5Index]?.san, "f5")

        XCTAssertEqual(
            game.moves.previousIndex(
                for: f5Index
            ),
            nf3Index
        )
    }
    
}
