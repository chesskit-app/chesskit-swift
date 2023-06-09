//
//  PGNParser.swift
//  ChessKit
//

import Foundation

/// Positional assessments.
enum PositionAnnotation {
    // <TBD>
}

/// Parses and converts the Portable Game Notation (PGN)
/// of a chess game.
///
public class PGNParser {
    
    /// Contains the contents of a single parsed move pair.
    private struct ParsedMove {
        /// The number of the move within the game.
        let number: Int
        /// The white move SAN string, annotation, and comment.
        let whiteMove: (san: String, annotation: Move.Assessment, comment: String)
        /// The black move SAN string, annotation, and comment (can be `nil`).
        let blackMove: (san: String, annotation: Move.Assessment, comment: String)?
        /// The result of the game, if applicable.
        let result: Result?
        
        enum Result: String {
            case whiteWin = "1-0"
            case blackWin = "0-1"
            case draw = "1/2-1/2"
        }
    }
    
    private init() {}
    
    // MARK: - Public
    
    /// Parses a PGN string and returns a game.
    ///
    /// - parameter pgn: The PGN string of a chess game.
    /// - parameter position: The starting position of the chess game.
    ///     Defaults to the standard position.
    /// - returns: A Swift representation of the chess game,
    ///     or `nil` if the PGN is invalid.
    ///
    public static func parse(
        game pgn: String,
        startingWith position: Position = .standard
    ) -> Game? {
        // ignoring tag pairs for now, movetext only
        
        let processedPGN = pgn
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        
        let range = NSRange(0..<processedPGN.utf16.count)
        let moves: [String]
        
        do {
            moves = try NSRegularExpression(pattern: PGNParser.Regex.full)
                .matches(in: processedPGN, range: range)
                .map {
                    NSString(string: pgn).substring(with: $0.range)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
        } catch {
            return nil
        }
        
        let parsedMoves = moves.compactMap { move -> ParsedMove? in
            let range = NSRange(0..<move.utf16.count)
            
            guard let moveNumberRange = move.range(of: Regex.moveNumber, options: .regularExpression),
                  let moveNumber = Int(move[moveNumberRange])
            else {
                return nil
            }
            
            let singleMoveRegex = "(\(Regex.castle)?|\(Regex.move)?)(\\s?\(Regex.annotation))?(\\s?\(Regex.comment))?"
            
            guard let m = try? NSRegularExpression(pattern: singleMoveRegex)
                    .matches(in: move, range: range)
                    .map({ NSString(string: move).substring(with: $0.range) }),
                  m.count >= 1 && m.count <= 2
            else {
                return nil
            }
            
            let whiteAnnotation = try? NSRegularExpression(pattern: Regex.annotation)
                .matches(in: m[0], range: NSRange(0..<m[0].utf16.count))
                .map {
                    Move.Assessment(rawValue: NSString(string: m[0]).substring(with: $0.range)) ?? .null
                }
                .first ?? .null
            
            let whiteComment = try? NSRegularExpression(pattern: Regex.comment)
                .matches(in: m[0], range: NSRange(0..<m[0].utf16.count))
                .map {
                    NSString(string: m[0]).substring(with: $0.range)
                        .replacingOccurrences(of: "{", with: "")
                        .replacingOccurrences(of: "}", with: "")
                }
                .first ?? ""
            
            var blackAnnotation: Move.Assessment?
            var blackComment: String?
            
            if m.count == 2 {
                blackAnnotation = try? NSRegularExpression(pattern: Regex.annotation)
                    .matches(in: m[1], range: NSRange(0..<m[1].utf16.count))
                    .map {
                        Move.Assessment(rawValue: NSString(string: m[1]).substring(with: $0.range)) ?? .null
                    }
                    .first ?? .null
                
                blackComment = try? NSRegularExpression(pattern: Regex.comment)
                    .matches(in: m[1], range: NSRange(0..<m[1].utf16.count))
                    .map {
                        NSString(string: m[1]).substring(with: $0.range)
                            .replacingOccurrences(of: "{", with: "")
                            .replacingOccurrences(of: "}", with: "")
                    }
                    .first ?? ""
            }
            
            let result = try? NSRegularExpression(pattern: Regex.result)
                .matches(in: move, range: range)
                .map {
                    NSString(string: move).substring(with: $0.range)
                }
                .first
            
            let whiteMove = (
                san: m[0],
                annotation: whiteAnnotation ?? .null,
                comment: whiteComment ?? ""
            )
            let blackMove = m.count == 2 ? (
                san: m[1],
                annotation: blackAnnotation ?? .null,
                comment: blackComment ?? ""
            ) : nil
            
            return ParsedMove(
                number: moveNumber,
                whiteMove: whiteMove,
                blackMove: blackMove,
                result: ParsedMove.Result(rawValue: result ?? "")
            )
        }
        
        let game = Game(startingWith: position)
        
        parsedMoves.forEach { move in
            let whiteIndex = MoveTree.Index(number: move.number, color: .white).previous
            guard let currentPosition = game.positions[whiteIndex] else {
                return
            }
            
            var white = SANParser.parse(move: move.whiteMove.san, in: currentPosition)
            white?.assessment = move.whiteMove.annotation
            white?.comment = move.whiteMove.comment
            
            if let white {
                game.make(move: white, from: whiteIndex)
            }
            
            // update position resulting from white move
            let blackIndex = MoveTree.Index(number: move.number, color: .black).previous
            guard let updatedPosition = game.positions[blackIndex] else {
                return
            }
            
            var black: Move?
            
            if let blackMove = move.blackMove {
                black = SANParser.parse(move: blackMove.san, in: updatedPosition)
                black?.assessment = move.blackMove?.annotation ?? .null
                black?.comment = move.blackMove?.comment ?? ""
            }
            
            if let black {
                game.make(move: black, from: blackIndex)
            }
        }
        
        return game
    }
    
    /// Converts a `Game` object into a PGN string.
    ///
    /// - parameter game: The chess game to convert.
    /// - returns: A string containing the PGN of `game`.
    ///
    public static func convert(game: Game) -> String {
        var pgn = ""
        
        for element in game.moves.pgnRepresentation {
            switch element {
            case .whiteNumber(let number):
                pgn += "\(number). "
            case .blackNumber(let number):
                pgn += "\(number)... "
            case let .move(move, _):
                pgn += movePGN(for: move)
            case .variationStart:
                pgn += "("
            case .variationEnd:
                pgn = pgn.trimmingCharacters(in: .whitespaces)
                pgn += ") "
            }
        }
        
        return pgn.trimmingCharacters(in: .whitespaces)
    }
    
    private static func movePGN(for move: Move) -> String {
        var result = ""
        
        result += "\(move.san) "
        
        if move.assessment != .null {
            result += "\(move.assessment.rawValue) "
        }
        
        if !move.comment.isEmpty {
            result += "{\(move.comment)} "
        }
        
        return result
    }
    
}
