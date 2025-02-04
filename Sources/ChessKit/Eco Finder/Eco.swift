//
//  Eco.swift
//  ChessKit
//
//  Created by Amir Zucker on 04/02/2025.
//

//TODO: 05/02/2025 - Consider adding UCI (LAN) moves notation as well as position EDP.

///A data object representing the chess opening
public struct Eco: Sendable {
    ///The name of the opening, for example: "Scotch Game"
    public let name: String
    ///The eco code of the opening, for example: "C45"
    public let ecoCode: String
    /// A pgn string representing the moves of this opening
    public let moves: String
    
    internal init(name: String, ecoCode: String, moves: String) {
        self.name = name
        self.ecoCode = ecoCode
        self.moves = moves
    }
}
