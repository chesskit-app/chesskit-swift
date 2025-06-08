//
//  PGNParser.swift
//  ChessKit
//

import Foundation

/// Parses and converts the Portable Game Notation (PGN)
/// of a chess game.
public enum PGNParser {

  // MARK: - Public

  /// Parses a PGN string and returns a game.
  ///
  /// - parameter pgn: The PGN string of a chess game.
  /// - returns: A Swift representation of the chess game.
  /// - throws: A ``PGNParser.Error`` indicating the first error
  /// encountered while parsing `pgn`.
  ///
  /// The parsing implementation is based on the [PGN Standard](https://www.saremba.de/chessgml/standards/pgn/pgn-complete.htm)'s
  /// import format.
  ///
  /// The starting position is read from the `FEN` tag if
  /// the `SetUp` tag is set to `1`. Otherwise the standard
  /// starting position is assumed.
  ///
  public static func parse(game pgn: String) throws(Error) -> Game {
    // initial processing

    let lines = pgn.components(separatedBy: .newlines)
      .map { $0.trimmingCharacters(in: .whitespaces) }
      // lines beginning with % are ignored
      .filter { $0.prefix(1) != "%" }

    let splitLines = lines.split(separator: "").map(Array.init)

    var tagPairLines = [String]()
    var moveTextLines = [String]()

    if splitLines.count == 2 {
      tagPairLines = splitLines[0]
      moveTextLines = splitLines[1]
    } else if splitLines.count == 1 {
      moveTextLines = splitLines[0]
    } else if splitLines.isEmpty {
      return .init(startingWith: .standard)
    } else {
      throw .tooManyLineBreaks
    }

    // parse tags

    let tags = try PGNTagParser.gameTags(from: tagPairLines.joined())

    var startingPosition: Position
    if tags.setUp == "1", let position = FENParser.parse(fen: tags.fen) {
      startingPosition = position
    } else if tags.setUp == "0" || (tags.setUp.isEmpty && tags.fen.isEmpty) {
      startingPosition = .standard
    } else {
      throw .invalidSetUpOrFEN
    }

    // parse movetext

    var game = try MoveTextParser.game(
      from: moveTextLines.joined(separator: " "),
      startingPosition: startingPosition
    )

    // return game with tags + movetext

    game.tags = tags
    return game
  }

  /// Converts a ``Game`` object into a PGN string.
  ///
  /// - parameter game: The chess game to convert.
  /// - returns: A string containing the PGN of `game`.
  ///
  /// The conversion implementation is based on the [PGN Standard](https://www.saremba.de/chessgml/standards/pgn/pgn-complete.htm)'s
  /// export format.
  ///
  public static func convert(game: Game) -> String {
    var pgn = ""

    // tags

    [
      game.tags.$event,
      game.tags.$site,
      game.tags.$date,
      game.tags.$round,
      game.tags.$white,
      game.tags.$black,
      game.tags.$result,
      game.tags.$annotator,
      game.tags.$plyCount,
      game.tags.$timeControl,
      game.tags.$time,
      game.tags.$termination,
      game.tags.$mode,
      game.tags.$fen,
      game.tags.$setUp
    ]
    .map(\.pgn)
    .filter { !$0.isEmpty }
    .forEach { pgn += $0 + "\n" }

    game.tags.other.sorted(by: <).forEach { key, value in
      pgn += "[\(key) \"\(value)\"]\n"
    }

    if !pgn.isEmpty {
      pgn += "\n"  // extra line between tags and movetext
    }

    // movetext

    for element in game.moves.pgnRepresentation {
      switch element {
      case let .whiteNumber(number):
        pgn += "\(number). "
      case let .blackNumber(number):
        pgn += "\(number)... "
      case let .move(move, _):
        pgn += movePGN(for: move)
      case let .positionAssessment(assessment):
        pgn += "\(assessment.rawValue) "
      case .variationStart:
        pgn += "("
      case .variationEnd:
        pgn = pgn.trimmingCharacters(in: .whitespaces)
        pgn += ") "
      }
    }

    pgn += game.tags.result

    return pgn.trimmingCharacters(in: .whitespaces)
  }

  // MARK: - Private

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

// MARK: - Error
extension PGNParser {
  public enum Error: Swift.Error, Equatable {
    /// There are too many line breaks in the provided PGN.
    /// PGN should contain a single blank line between the
    /// tags and move text.
    case tooManyLineBreaks
    /// If included in the PGN's tag pairs, the `SetUp` tag must
    /// be set to either `"0"` or `"1"`.
    ///
    /// If `"0"`, the `FEN` tag must be blank. If `1`, the
    /// `FEN` tag must contain a valid FEN string representing
    /// the starting position of the game.
    ///
    /// - seealso: ``FENParser``
    case invalidSetUpOrFEN

    // tags
    /// Tags must be surrounded by brackets with an unquoted
    /// string (key) followed by a quoted string (value) inside.
    ///
    /// For example: `[Round "29"]`
    case invalidTagFormat
    /// Tags must have an open bracket (`[`) and a close bracket (`]`).
    /// If there is a close bracket without an open, this error
    /// will be thrown.
    case mismatchedTagBrackets
    /// Tag string (value) could not be parsed.
    case stringNotFound
    /// Tag symbol (key) could not be parsed.
    case symbolNotFound
    /// Tag symbols must be either letters, numbers, or underscores (`_`).
    case unexpectedCharacter(String)

    // move text
    /// The move or position assessment annotation is invalid.
    case invalidAnnotation(String)
    /// The move SAN is invalid for the implied position given
    /// by its location within the PGN string.
    case invalidMove(String)
    /// The first item in a move text string must be either a
    /// number (e.g. `1.`) or a move SAN (e.g. `e4`).
    case unexpectedMoveTextToken
    /// Comments must be enclosed on both sides by braces (`{`, `}`).
    case unpairedCommentDelimiter
    /// Variations must be enclosed on both sides by parentheses (`(`, `)`).
    case unpairedVariationDelimiter
  }
}
