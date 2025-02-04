//
//  EcoFinder.swift
//  ChessKit
//
//  Created by Amir Zucker on 03/02/2025.
//

import Foundation


///Find an ECO (encyclopedia of chess openings) in the internal openings library of ChessKit framework.
///Openings library file curtesy of [lichess openings library](https://github.com/lichess-org/chess-openings/tree/master)
public struct EcoFinder: Sendable {
    //Dictionary maping of pgn moves string and the index of the eco at ``_ecosArray``
    private let ecoByMovesDictionary: [String: Int]
    
    //Dictionary maping of ECO names string and the index of the eco at ``_ecosArray``
    private let ecoByNameDictionary: [String: Int]
    
    //The actual ECO data
    private let ecosArray: [Eco]
    
    /// Loads the openings file in the background and init the EcoFinder
    /// - Throws: FileNotFound - If there is no ECO file at the expected location
    /// - Throws: CouldNotOpenFile - if file read has failed for some reason
    /// - Note: As long as this framework is unmodified, errors should never be thrown as the eco file is bundles with the framework itself.
    public init() async throws {
        guard let fileUrl = Bundle.module.url(forResource: "eco", withExtension: "tsv") else { throw EcoFinderError.FileNotFound }
        guard let file = freopen(fileUrl.path(), "r", stdin) else { throw EcoFinderError.CouldNotOpenFile }
        defer { fclose(file) }
        
        var ecoByMovesDictionary: [String: Int] = [:]
        var ecoByNameDictionary: [String: Int] = [:]
        var ecosArray: [Eco] = []
        
        while let line = readLine() {
            let line = line.split(separator: "\t")
            guard line.count == 3 else {
                print(line)
                continue
            }
            
            let ecoCode = String(line[0])
            let name = String(line[1]).replacingOccurrences(of: "\"", with: "")
            let moves = String(line[2])
            
            let eco = Eco(name: name, ecoCode: ecoCode, moves: moves)
            ecosArray.append(eco)
            ecoByMovesDictionary[moves] = ecosArray.count - 1
            ecoByNameDictionary[name] = ecosArray.count - 1
        }
        
        self.ecoByMovesDictionary = ecoByMovesDictionary
        self.ecoByNameDictionary = ecoByNameDictionary
        self.ecosArray = ecosArray
    }
    
    /// searchs for an opening for a given moves array from the first move
    /// until no opening is found and return the last found opening.
    /// ```swift
    /// //Examples:
    /// let pgn = "1. e4 e5" //Will return King's Pawn Game
    /// let pgn = "1. e4 e5 2. Ke2" //Will return Bongcloud Attack
    /// let pgn = "1. e4 e5 2. Ke2 Nf6" //Should still return Bongcloud Attack
    /// ```
    ///
    /// - parameter moves: an ordered array of moves to search an opening for.
    ///
    /// - returns: an ECO object for the moves array.
    ///
    /// - Throws: EcoNotFound excetion if no ECO found for the given pgn string. Since all possible first moves are covered, receiving this probably means something is wrong with the input
    public func searchEco(moves: [Move]) throws -> Eco {
        var pgn: String = ""

        for (index, move) in moves.enumerated() {
            if index % 2 == 0 {
                pgn += "\(index / 2 + 1). \(move.san)"
            } else {
                pgn.append(" \(move.san) ")
            }
        }
        
        return try searchEco(pgn: pgn)
    }
    
    /// searchs for an opening for a given PGN starting from the first move
    /// until no opening is found and return the last found opening.
    /// ```swift
    /// //Examples:
    /// let pgn = "1. e4 e5" //Will return King's Pawn Game
    /// let pgn = "1. e4 e5 2. Ke2" //Will return Bongcloud Attack
    /// let pgn = "1. e4 e5 2. Ke2 Nf6" //Should still return Bongcloud Attack
    /// ```
    ///
    /// - parameter pgn: a PGN of moves only string to search an opening for without any additional annotations.
    ///
    /// - returns: an ECO object for that PGN.
    ///
    /// - Throws: EcoNotFound excetion if no ECO found for the given pgn string. Since all possible first moves are covered, receiving this probably means something is wrong with the input
    public func searchEco(pgn: String) throws -> Eco {
        var eco = getEco(pgn: pgn)
        
        if eco == nil { //No exact PGN found, start searching for a matching opening
            let regex = /\d+\.{1}/ //Search for move number for example "2." "101." etc to use as a separator
            let movesArray = pgn.split(separator: regex)
                .enumerated()
                .map{ index, value in
                    let cleanValue = value.trimmingCharacters(in: .whitespacesAndNewlines) // remove leftover white spaces
                    return "\(index + 1). \(cleanValue)" //restore the move number that was removed in the split function
                }

            //Increnetally search for an opening until a specific opening is not found
            //and returns the last found opening.
            //This is done incrementally and not decrementally since searching an eco
            //decramentally on an entire game would most likely be less efficient.
            //Opening moves can end on either white or black move,
            //therefore we most check both black and white moves.
            for index in 0..<movesArray.count {
                let currentMoves = movesArray[0...index]
                
                //Substing of white's move including the move number.
                guard let lastWhiteMove = currentMoves.last?
                    .split(separator: " ")
                    .dropLast()
                    .joined(separator: " ") else { break }
                
                //Remove the last full move and append only white's move.
                var whiteMoveSplit = currentMoves.dropLast()
                whiteMoveSplit.append(lastWhiteMove)
                
                let whitePGN = whiteMoveSplit.joined(separator: " ")
                let currentPGN = currentMoves.joined(separator: " ")
                let tempWhiteEco = getEco(pgn: whitePGN)
                let fullMoveEco = getEco(pgn: currentPGN)
                
                //If we reached a point where both white and black ecos are nil
                //we have already found the longest eco, in the previous iteration.
                if tempWhiteEco == nil &&
                    fullMoveEco == nil {
                    break
                }
                
                //try assigning the longer eco found first
                eco = fullMoveEco ?? tempWhiteEco
            }
        }
        
        guard let eco else {
            throw EcoFinderError.EcoNotFound(pgn)
        }
        
        return eco
    }
    
    /// get an opening for an exact given Moves array.
    ///
    /// ```swift
    /// //Examples (PGN representation):
    /// let pgn = "1. e4 e5" //Will return King's Pawn Game
    /// let pgn = "1. e4 e5 2. Ke2" //Will return Bongcloud Attack
    /// let pgn = "1. e4 e5 2. Ke2 Nf6" //Will return nil since there is no such exact opening.
    /// ```
    ///
    /// - parameter moves: an array of moves to retreive an opening for.
    ///
    /// - returns: an ECO object for that moves array or nil if not found
    public func getEco(moves: [Move]) -> Eco? {
        var pgn: String = ""

        for (index, move) in moves.enumerated() {
            if index % 2 == 0 {
                pgn += "\(index / 2 + 1). \(move.san)"
            } else {
                pgn.append(" \(move.san) ")
            }
        }
        
        return getEco(pgn: pgn)
    }
    
    /// get an opening for an exact given PGN string.
    ///
    /// ```swift
    /// //Examples:
    /// let pgn = "1. e4 e5" //Will return King's Pawn Game
    /// let pgn = "1. e4 e5 2. Ke2" //Will return Bongcloud Attack
    /// let pgn = "1. e4 e5 2. Ke2 Nf6" //Will return nil since there is no such exact opening.
    /// ```
    ///
    /// - parameter moves: an array of moves to retreive an opening for.
    ///
    /// - returns: an ECO object for that PGN or nil if not found
    public func getEco(pgn: String) -> Eco? {
        let index = ecoByMovesDictionary[pgn] ?? -1
        return ecosArray[safe: index]
    }
    
    /// get an opening for an exact given eco name string.
    /// see eco.tsv file for list of names.
    ///
    /// ```swift
    /// //Examples:
    /// let openingName = "King's Pawn Game" //Will return Eco(name: "King's Pawn Game", ecoCode: "C20", moves: "1. e4 e5")
    /// let openingName = "Bongcloud Attack" //Will return Eco(name: "Bongcloud Attack", ecoCode: "C20", moves: "1. e4 e5 2. Ke2")
    /// let openingName = "King's Pawn Game:" //Will return nil since there is no such exact opening.
    /// ```
    ///
    /// - parameter moves: an array of moves to retreive an opening for.
    ///
    /// - returns: an ECO object for that PGN or nil if not found
    public func getEco(ecoName: String) -> Eco? {
        let index = ecoByNameDictionary[ecoName] ?? -1
        return ecosArray[safe: index]
    }
}



//Neat little extension to prevent app crash if there is no such index
private extension Collection {
    subscript (safe index: Index) -> Element? {
        guard index >= self.startIndex && index < self.endIndex else { return nil }
        return self[index]
    }
}
