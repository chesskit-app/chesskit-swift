//
//  EcoFinder.swift
//  ChessKit
//
//  Created by Amir Zucker on 03/02/2025.
//

import Foundation

//TODO: UPDATE LIBRARY DOCS WITH OPENING FINDER FEATURE AND EXAMPLE

/// Find an ECO [(encyclopedia of chess openings)](https://en.wikipedia.org/wiki/Encyclopaedia_of_Chess_Openings) in the internal openings library of ChessKit framework.
/// Openings library file curtesy of [lichess openings library](https://github.com/lichess-org/chess-openings/tree/master)
public struct EcoFinder: Sendable {
    /// Dictionary maping of PGN moves string and the index of the eco at `ecosArray`
    private let ecoByMovesDictionary: [String: Int]
    
    /// Dictionary maping of EDP position string and the index of the eco at `ecosArray`
    //(EDP is a FEN without move counter according to lichess' git repo, but it's an incorrect definition)
    private let ecoByEDPDictionary: [String: Int]
    
    /// Dictionary maping of ECO names string and the index of the eco at `ecosArray`
    private let ecoByNameDictionary: [String: Int]
    
    /// The actual ECO data
    private let ecosArray: [Eco]
    
    /// Loads the openings file in the background and init the EcoFinder
    /// - Throws: ``EcoFinderError/FileNotFound`` - If there is no ECO file at the expected location
    /// - Throws: ``EcoFinderError/CouldNotOpenFile`` - if file read has failed for some reason
    /// - Note: As long as this framework is unmodified, errors should never be thrown as the eco file is bundles with the framework itself.
    public init() throws {
        guard let filePath = Bundle.module.path(forResource: "eco", ofType: "tsv") else {
            throw EcoFinderError.FileNotFound
        }
        guard let fileContent = try? String(contentsOfFile: filePath, encoding: .utf8) else {
            throw EcoFinderError.CouldNotOpenFile
        }
        let lines = fileContent.split(whereSeparator: \.isNewline)
        
        var ecoByMovesDictionary: [String: Int] = [:]
        var ecoByEDPDictionary: [String: Int] = [:]
        var ecoByNameDictionary: [String: Int] = [:]
        var ecosArray: [Eco] = []
        
        for line in lines {
            let components = line.split(separator: "\t")
            guard components.count == 4 else { continue } // We have 4 columns in eco.tsv file, this is a very rudimentary check that the data is some what valid.
            
            let ecoCode = String(components[0])
            let name = String(components[1]).replacingOccurrences(of: "\"", with: "")
            let moves = String(components[2])
            let edp = String(components[3])
            
            let eco = Eco(name: name, ecoCode: ecoCode, moves: moves, fen: edp)
            ecosArray.append(eco)
            ecoByMovesDictionary[moves] = ecosArray.count - 1
            ecoByEDPDictionary[edp] = ecosArray.count - 1
            ecoByNameDictionary[name] = ecosArray.count - 1
        }
        
        self.ecoByMovesDictionary = ecoByMovesDictionary
        self.ecoByEDPDictionary = ecoByEDPDictionary
        self.ecoByNameDictionary = ecoByNameDictionary
        self.ecosArray = ecosArray
    }
    
    /// Search for an opening for a given Move array starting from the first move
    /// until no opening is found or last move was reached and returns the last found opening.
    ///
    /// Examples (SAN representation):
    /// ```swift
    /// let san = "1. e4 e5" //Will return King's Pawn Game
    /// let san = "1. e4 e5 2. Ke2" //Will return Bongcloud Attack
    /// let san = "1. e4 e5 2. Ke2 Nf6" //Will still return Bongcloud Attack as Nf6 is no longer part of the opening move set.
    /// ```
    ///
    /// - parameter moves: An array of moves to search an opening for. This method assumes the array is ordered by move number, white first.
    ///
    /// - returns: An ECO object representing the opening for that Move array.
    ///
    /// - Throws: ``EcoFinderError/EcoNotFound`` excetion if no ECO found for the given Move array. Since all possible first moves are covered, receiving this probably means something is wrong with the input
    public func searchEco(for moves: [Move]) throws -> Eco {
        return try searchEcoForMovesArray(moves)
    }
    
    /// Search for an opening for a given PGN starting from the first move
    /// until no opening is found or last move was reached and returns the last found opening.
    ///
    /// Examples:
    /// ```swift
    /// let pgn = "1. e4 e5" //Will return King's Pawn Game
    /// let pgn = "1. e4 e5 2. Ke2" //Will return Bongcloud Attack
    /// let pgn = "1. e4 e5 2. Ke2 Nf6" //Should still return Bongcloud Attack
    /// ```
    ///
    /// - parameter pgn: A string representation of the game using standard PGN notation.
    ///
    /// - returns: An ECO object representing the opening for that PGN.
    ///
    /// - Throws: ``EcoFinderError/EcoNotFound`` excetion if no ECO found for the given PGN string. Since all possible first moves are covered, receiving this probably means something is wrong with the input
    /// - NOTE: This function should work for SAN notation as well.
    /// - NOTE: For FEN strings, use ``getEco(for:)-5d0ig`` as FENs only have one possible output.
    public func searchEco(for pgn: String) throws -> Eco {
        let moves: [Move] = parsePGN(pgn)
        return try searchEcoForMovesArray(moves)
    }
    
    /// Search for an opening for a given Game starting from the first move
    /// until no opening is found or last move was reached and returns the last found opening.
    ///
    /// - parameter game: A ``Game`` object.
    ///
    /// - returns: An ECO object representing the opening for that game.
    ///
    /// - Throws: ``EcoFinderError/EcoNotFound`` excetion if no ECO found for the given Game. Since all possible first moves are covered, receiving this probably means something is wrong with the input
    ///
    /// - NOTE: This search function does not take into considerations the FEN of the position
    /// as there is exactly one possible FEN result. To retreive the opening assocciated with the FEN
    /// of the current position use ``getEco(for:)-96lrs``
    public func searchEco(for game: Game) throws -> Eco {
        let moves: [Move] = parseGame(game)
        return try searchEcoForMovesArray(moves)
    }
    
    /// Get an opening for a given Move array, no search is performed,
    ///
    /// Examples (SAN representation):
    /// ```swift
    /// let san = "1. e4 e5" //Will return King's Pawn Game
    /// let san = "1. e4 e5 2. Ke2" //Will return Bongcloud Attack
    /// let san = "1. e4 e5 2. Ke2 Nf6" //Will return nil since there is no such exact opening.
    /// ```
    ///
    /// - parameter moves: an array of moves to retreive an opening for.
    ///
    /// - returns: An ECO object representing the opening for that Move array or nil if not found
    public func getEco(for moves: [Move]) -> Eco? {
        let cleanPGN = parseMoves(moves: moves)
        return getEcoForMovesPGN(cleanPGN)
    }
    
    /// Get an opening for an exact given position string.
    ///
    /// Examples:
    /// ```swift
    /// let pgn = "1. e4 e5" //Will return King's Pawn Game
    /// let pgn = "1. e4 e5 2. Ke2" //Will return Bongcloud Attack
    /// let pgn = "1. e4 e5 2. Ke2 Nf6" //Will return nil since there is no such exact opening.
    /// let fen = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -" //Will return King's Pawn Game
    /// let fen = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPPKPPP/RNBQ1BNR b kq -" //Will return Bongcloud Attack
    /// let fen = "rnbqkb1r/pppp1ppp/5n2/4p3/4P3/8/PPPPKPPP/RNBQ1BNR w kq -" //Will return nil since there is no such exact opening.
    /// ```
    ///
    /// - parameter position: A string representation of the current position.
    /// - parameter positionType: The type of position supplied in the position string parameter
    ///
    /// - returns: An ECO object representing the opening for that position or nil if not found
    ///
    /// - NOTE: For FEN results, we ignore the move counter.
    /// PGN should work for SAN notation as well.
    public func getEco(for position: String, positionType: PositionType) -> Eco? {
        switch positionType {
        case .PGN:
            let cleanPGN: String = parsePGN(position)
            return getEcoForMovesPGN(cleanPGN)
        case .FEN:
            let cleanFen = parseFEN(position)
            return getEcoForFen(cleanFen)
        }
    }
    
    /// Get an opening for a Game object.
    /// This function tries to retrieve the opening assocciated with the game PGN.
    /// If PGN fails, we try to retrieve the opening assocciated with the FEN of the current position
    /// or start position FEN if it still fails. 
    ///
    /// - parameter game: A ``Game`` object.
    ///
    /// - returns: An ECO object representing the opening for that game or nil if not found
    ///
    /// - NOTE: For FEN results, we ignore the move counter.
    public func getEco(for game: Game) -> Eco? {
        let cleanPGN: String = parseGame(game)
        if let eco = getEcoForMovesPGN(cleanPGN) {
            return eco
        }
        
        let currentIndex = game.moves.endIndex
        let startIndex = game.moves.startIndex
        if let position = game.positions[currentIndex],
            let eco = getEco(for: position) {
            return eco
        }
        
        if let position = game.positions[startIndex] {
            return getEco(for: position)
        }
        
        return nil
    }
    
    /// Get an opening for a Position object.
    /// This function tries to retrieve the opening assocciated with the position FEN.
    ///
    /// - parameter position: A ``Position`` object.
    ///
    /// - returns: An ECO object representing the opening for that position or nil if not found
    public func getEco(for position: Position) -> Eco? {
        let fenString = position.fen
        let parsedFen = parseFEN(fenString)
        
        return getEcoForFen(parsedFen)
    }
    
    /// get an opening for an exact given eco name string.
    /// See eco.tsv file for list of names.
    ///
    /// Examples:
    /// ```swift
    /// let openingName = "King's Pawn Game" //Will return Eco(name: "King's Pawn Game", ecoCode: "C20", moves: "1. e4 e5")
    /// let openingName = "Bongcloud Attack" //Will return Eco(name: "Bongcloud Attack", ecoCode: "C20", moves: "1. e4 e5 2. Ke2")
    /// let openingName = "King's Pawn Game:" //Will return nil since there is no such exact opening.
    /// let openingName = "Bongcloud" //Will return nil since there is no such exact opening.
    /// ```
    ///
    /// - parameter ecoName: The name of the opening to retrieve.
    ///
    /// - returns: An ECO object representing the opening for that opening name or nil if not found
    ///
    /// - NOTE: This is a simple get by name function, meaning it assumes the name is correct and accurate
    /// to how it's written in eco.tsv file. If you are unsure of the opening name,
    /// it's best to use one of the other functions.
    public func getEco(by ecoName: String) -> Eco? {
        let index = ecoByNameDictionary[ecoName] ?? -1
        return ecosArray[safe: index]
    }
}

//MARK: private functions
private extension EcoFinder {
    private func parsePGN(_ pgn: String) -> String {
        guard let game = PGNParser.parse(game: pgn) else { return "" }
        
        return parseGame(game)
    }
    
    private func parseGame(_ game: Game) -> String {
        let moves: [Move] = parseGame(game)
        return parseMoves(moves: moves)
    }
    
    private func parsePGN(_ pgn: String) -> [Move] {
        guard let game = PGNParser.parse(game: pgn) else { return [] }
        
        return parseGame(game)
    }
    
    private func parseGame(_ game: Game) -> [Move] {
        return game.moves
            .dictionary
            .sorted(by: {
                $0.key.number == $1.key.number ?
                $0.key.color == .white :
                $0.key.number < $1.key.number
            })
            .compactMap { $0.value.move }
    }
    
    private func parseMoves(moves: [Move]) -> String {
        var pgn: String = ""

        for (index, move) in moves.enumerated() {
            if index % 2 == 0 {
                pgn += "\(index / 2 + 1). \(move.san)"
            } else {
                pgn.append(" \(move.san) ")
            }
        }
        
        return pgn.trimmingCharacters(in: .whitespaces)
    }
    
    private func parseFEN(_ fen: String) -> String {
        var fen = fen.components(separatedBy: .whitespaces)
        // Remove move counters.
        // Since opening have an en passant option, we can use the last "-" in the FEN string
        // which represent en passant as the trimming point instead of using complicated regexes.
        while !fen.isEmpty, fen.last != "-" {
            fen.removeLast()
        }
        
        return fen.joined(separator: " ")
    }
    
    private func searchEcoForMovesArray(_ moves: [Move]) throws -> Eco {
        var moves = moves
        var eco: Eco? = nil
        
        repeat {
            let pgn = parseMoves(moves: moves)
            eco = getEcoForMovesPGN(pgn)
            
            if !moves.isEmpty {
                moves.removeLast()
            }
        } while eco == nil && !moves.isEmpty
        
        guard let eco else {
            throw EcoFinderError.EcoNotFound
        }
        
        return eco
    }
    
    private func getEcoForFen(_ fen: String) -> Eco? {
        let index = ecoByEDPDictionary[fen] ?? -1
        return ecosArray[safe: index]
    }
    
    private func getEcoForMovesPGN(_ pgn: String) -> Eco? {
        let index = ecoByMovesDictionary[pgn] ?? -1
        return ecosArray[safe: index]
    }
}

//Neat little extension to prevent app crash if index is out of bounds.
private extension Collection {
    subscript (safe index: Index) -> Element? {
        guard index >= self.startIndex && index < self.endIndex else { return nil }
        return self[index]
    }
}
