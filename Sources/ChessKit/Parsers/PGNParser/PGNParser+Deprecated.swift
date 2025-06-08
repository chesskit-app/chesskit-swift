//
//  PGNParser+Deprecated.swift
//  ChessKit
//

import Foundation

/// Parses and converts the Portable Game Notation (PGN)
/// of a chess game.
public extension PGNParser {

  /// Contains the contents of a single parsed move pair.
  private struct ParsedMove {
    /// The number of the move within the game.
    let number: Int
    /// The white move SAN string, annotation, and comment.
    let whiteMove: (san: String, annotation: Move.Assessment, comment: String)
    /// The black move SAN string, annotation, and comment (can be `nil`).
    let blackMove: (san: String, annotation: Move.Assessment, comment: String)?
    /// The result of the game, if applicable.
    let result: String?
  }

  // MARK: - Public

  /// Parses a PGN string and returns a game.
  ///
  /// - parameter pgn: The PGN string of a chess game.
  /// - parameter position: The starting position of the chess game.
  ///     Defaults to the standard position.
  /// - returns: A Swift representation of the chess game.
  ///
  @available(*, deprecated, renamed: "parse(game:)")
  static func parse(
    game pgn: String,
    startingWith position: Position = .standard
  ) -> Game {
    let processedPGN =
      pgn
      .replacingOccurrences(of: "\n", with: " ")
      .replacingOccurrences(of: "\r", with: " ")

    let range = NSRange(0..<processedPGN.utf16.count)

    // tags

    let tags: [(String, String)]? = try? NSRegularExpression(pattern: Pattern.tags)
      .matches(in: processedPGN, range: range)
      .map {
        NSString(string: pgn).substring(with: $0.range)
          .trimmingCharacters(in: .whitespacesAndNewlines)
      }
      .compactMap { tag in
        let tagRange = NSRange(0..<tag.utf16.count)

        let matches = try? NSRegularExpression(pattern: Pattern.tagPair)
          .matches(in: tag, range: tagRange)

        if let match = matches?.first, match.numberOfRanges >= 3 {
          let key = match.range(at: 1)
          let value = match.range(at: 2)

          return (
            NSString(string: tag).substring(with: key)
              .trimmingCharacters(in: .whitespacesAndNewlines),
            NSString(string: tag).substring(with: value)
              .trimmingCharacters(in: .whitespacesAndNewlines)
          )
        } else {
          return nil
        }
      }

    let parsedTags = parsed(tags: Dictionary<String, String>(tags ?? []) { a, _ in a })

    // movetext

    let moveText: [String]

    moveText = try! NSRegularExpression(pattern: Pattern.moveText)
      .matches(in: processedPGN, range: range)
      .map {
        NSString(string: pgn).substring(with: $0.range)
          .trimmingCharacters(in: .whitespacesAndNewlines)
      }

    let parsedMoves = moveText.compactMap { move -> ParsedMove? in
      let range = NSRange(0..<move.utf16.count)

      guard let moveNumberRange = move.range(of: Pattern.moveNumber, options: .regularExpression),
        let moveNumber = Int(move[moveNumberRange])
      else {
        return nil
      }

      guard
        let m = try? NSRegularExpression(pattern: Pattern.singleMove)
          .matches(in: move, range: range)
          .map({ NSString(string: move).substring(with: $0.range) }),
        m.count >= 1 && m.count <= 2
      else {
        return nil
      }

      let whiteMove =
        try? NSRegularExpression(pattern: SANParser.Pattern.full)
        .matches(in: m[0], range: NSRange(0..<m[0].utf16.count))
        .compactMap {
          NSString(string: m[0]).substring(with: $0.range)
        }
        .first ?? ""

      let whiteAnnotation =
        try? NSRegularExpression(pattern: Pattern.annotation)
        .matches(in: m[0], range: NSRange(0..<m[0].utf16.count))
        .compactMap {
          Move.Assessment(rawValue: NSString(string: m[0]).substring(with: $0.range))
        }
        .first ?? .null

      let whiteComment =
        try? NSRegularExpression(pattern: Pattern.comment)
        .matches(in: m[0], range: NSRange(0..<m[0].utf16.count))
        .compactMap {
          NSString(string: m[0]).substring(with: $0.range)
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
        }
        .first ?? ""

      var blackMove: String?
      var blackAnnotation: Move.Assessment?
      var blackComment: String?

      if m.count == 2 {
        blackMove =
          try? NSRegularExpression(pattern: SANParser.Pattern.full)
          .matches(in: m[1], range: NSRange(0..<m[1].utf16.count))
          .compactMap {
            NSString(string: m[1]).substring(with: $0.range)
          }
          .first ?? ""

        blackAnnotation =
          try? NSRegularExpression(pattern: Pattern.annotation)
          .matches(in: m[1], range: NSRange(0..<m[1].utf16.count))
          .compactMap {
            Move.Assessment(rawValue: NSString(string: m[1]).substring(with: $0.range))
          }
          .first ?? .null

        blackComment =
          try? NSRegularExpression(pattern: Pattern.comment)
          .matches(in: m[1], range: NSRange(0..<m[1].utf16.count))
          .compactMap {
            NSString(string: m[1]).substring(with: $0.range)
              .replacingOccurrences(of: "{", with: "")
              .replacingOccurrences(of: "}", with: "")
          }
          .first ?? ""
      }

      let result = try? NSRegularExpression(pattern: Pattern.result)
        .matches(in: move, range: range)
        .map {
          NSString(string: move).substring(with: $0.range)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        .first

      let whiteMoveComponents = (
        san: whiteMove ?? "",
        annotation: whiteAnnotation ?? .null,
        comment: whiteComment ?? ""
      )
      let blackMoveComponents =
        m.count == 2
        ? (
          san: blackMove ?? "",
          annotation: blackAnnotation ?? .null,
          comment: blackComment ?? ""
        ) : nil

      return ParsedMove(
        number: moveNumber,
        whiteMove: whiteMoveComponents,
        blackMove: blackMoveComponents,
        result: result
      )
    }

    var game = Game(startingWith: position, tags: parsedTags)

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

      if let result = move.result {
        game.tags.result = result
      }
    }

    return game
  }

  // MARK: - Private

  private static func parsed(tags: [String: String]) -> Game.Tags {
    var gameTags = Game.Tags()

    tags.forEach { key, value in
      switch key.lowercased() {
      case "event": gameTags.event = value
      case "site": gameTags.site = value
      case "date": gameTags.date = value
      case "round": gameTags.round = value
      case "white": gameTags.white = value
      case "black": gameTags.black = value
      case "result": gameTags.result = value
      case "annotator": gameTags.annotator = value
      case "plycount": gameTags.plyCount = value
      case "timecontrol": gameTags.timeControl = value
      case "time": gameTags.time = value
      case "termination": gameTags.termination = value
      case "mode": gameTags.mode = value
      case "fen": gameTags.fen = value
      case "setup": gameTags.setUp = value
      default: gameTags.other[key] = value
      }
    }

    return gameTags
  }

  /// Contains useful regex strings for PGN parsing.
  private struct Pattern {
    // tag pair components
    static let tags = #"\[[^\]]+\]"#
    static let tagPair = #"\[([^"]+?)\s"([^"]+)"\]"#

    // move text
    static let moveText = #"\d{1,}\.{1,3}\s?(([Oo0]-[Oo0](-[Oo0])?|[KQRBN]?[a-h]?[1-8]?x?[a-h][1-8](\=[QRBN])?[+#]?)([\?!]{1,2})?(\s?\$\d)?(\s?\{.+?\})?(\s(1-0|0-1|1\/2-1\/2|\*)\s*$)?\s?){1,2}"#
    static let moveNumber = #"^\d{1,}"#
    static let singleMove = "\(SANParser.Pattern.full)(\\s?\(annotation))?(\\s?\(comment))?"
    static let result = #"(\s(1-0|0-1|1\/2-1\/2|\*)\s?){1}$"#

    // move pair components
    static let annotation = #"\$\d"#
    static let comment = #"\{.+?\}"#
  }

}
