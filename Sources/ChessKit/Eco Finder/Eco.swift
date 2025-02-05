//
//  Eco.swift
//  ChessKit
//
//  Created by Amir Zucker on 04/02/2025.
//

//UCI (LAN) moves notation can be easily added if there is ever a need for it.
//Just add the UCI to the tsv file and update the EcoFinder
//init function accordingly.

/// A data object representing the chess opening
public struct Eco: Sendable {
    /// The name of the opening, for example: "Scotch Game"
    public let name: String
    /// The eco code of the opening, for example: "C45"
    public let ecoCode: String
    /// A pgn string representing the moves of this opening
    public let moves: String
    /// A fen string representing the position of this opening
    public let fen: String
    
    internal init(name: String, ecoCode: String, moves: String, fen: String) {
        self.name = name
        self.ecoCode = ecoCode
        self.moves = moves
        self.fen = fen
    }
}
