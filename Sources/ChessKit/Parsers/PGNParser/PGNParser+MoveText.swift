//
//  PGNParser+MoveText.swift
//  ChessKit
//

import Foundation

extension PGNParser {
  enum MoveTextParser {

    // MARK: - Internal

    static func game(
      from moveText: String,
      startingPosition: Position
    ) throws(PGNParser.Error) -> Game {
      let moveTextTokens = try MoveTextParser.tokenize(
        moveText: moveText
      )

      return try MoveTextParser.parse(tokens: moveTextTokens, startingWith: startingPosition)
    }

    // MARK: - Private

    private static func tokenize(moveText: String) throws(PGNParser.Error) -> [Token] {
      let inlineMoveText = moveText.components(separatedBy: .newlines).joined(separator: "")
      var iterator = inlineMoveText.makeIterator()

      var tokens = [Token]()
      var currentTokenType = TokenType.none
      var currentToken = ""

      while let c = iterator.next() {
        if c == "{" {
          currentTokenType = .comment
        } else if c == "}" {
          if currentTokenType != .comment {
            throw .unpairedCommentDelimiter
          } else {
            if !currentToken.isEmpty, let token = currentTokenType.convert(currentToken) {
              tokens.append(token)
            }

            currentTokenType = .none
          }
        } else if currentTokenType == .comment || currentTokenType.isValid(character: c) {
          currentToken += String(c)
        } else {
          if !currentToken.isEmpty, let token = currentTokenType.convert(currentToken) {
            tokens.append(token)
          }

          currentTokenType = .match(character: c)
          currentToken = String(c)
        }
      }

      if !currentToken.isEmpty, let token = currentTokenType.convert(currentToken) {
        tokens.append(token)
      }

      return tokens
    }

    private static func parse(
      tokens: [Token],
      startingWith position: Position
    ) throws(PGNParser.Error) -> Game {
      var game = Game(startingWith: position)
      var iterator = tokens.makeIterator()

      var currentToken = iterator.next()
      var currentMoveIndex: MoveTree.Index

      // determine if first move is white or black

      if case let .number(number) = currentToken, let n = Int(number.prefix { $0 != "." }) {
        if number.filter({ $0 == "." }).count >= 3 {
          currentMoveIndex = .init(number: n, color: .black).previous
        } else {
          currentMoveIndex = .init(number: n, color: .white).previous
        }
      } else if case let .san(san) = currentToken {
        currentMoveIndex = position.sideToMove == .white ? .minimum : .minimum.next
        if let position = game.positions[currentMoveIndex] {
          if let move = SANParser.parse(move: san, in: position) {
            currentMoveIndex = game.make(move: move, from: currentMoveIndex)
          } else {
            throw .invalidMove(san)
          }
        }
      } else {
        throw .unexpectedMoveTextToken
      }

      // iterate through remaining tokens

      var variationStack = Stack<MoveTree.Index>()

      while let token = iterator.next() {
        currentToken = token

        switch currentToken {
        case .none, .number, .result:
          break
        case let .san(san):
          if let position = game.positions[currentMoveIndex],
            let move = SANParser.parse(move: san, in: position)
          {
            currentMoveIndex = game.make(move: move, from: currentMoveIndex)
          } else {
            throw .invalidMove(san)
          }
        case let .annotation(annotation):
          if let rawValue = firstMatch(
            in: annotation, for: .numericPosition
          ), let positionAssessment = Position.Assessment(rawValue: rawValue) {
            game.annotate(
              positionAt: currentMoveIndex,
              assessment: positionAssessment
            )
            continue
          }

          var moveAssessment: Move.Assessment?

          if let notation = firstMatch(in: annotation, for: .traditional) {
            moveAssessment = .init(notation: notation)
          } else if let rawValue = firstMatch(in: annotation, for: .numericMove) {
            moveAssessment = .init(rawValue: rawValue)
          } else {
            throw .invalidAnnotation(annotation)
          }

          if let moveAssessment {
            game.annotate(moveAt: currentMoveIndex, assessment: moveAssessment)
          } else {
            throw .invalidAnnotation(annotation)
          }
        case let .comment(comment):
          game.annotate(moveAt: currentMoveIndex, comment: comment)
        case .variationStart:
          variationStack.push(currentMoveIndex)
          currentMoveIndex = currentMoveIndex.previous
        case .variationEnd:
          if let index = variationStack.pop() {
            currentMoveIndex = index
          } else {
            throw .unpairedVariationDelimiter
          }
        }
      }

      return game
    }

    private static func firstMatch(in string: String, for pattern: Pattern) -> String? {
      let matches = try? NSRegularExpression(pattern: pattern.rawValue)
        .matches(in: string, range: NSRange(0..<string.utf16.count))

      if let match = matches?.first {
        return NSString(string: string).substring(with: match.range)
      } else {
        return nil
      }
    }

    private enum Pattern: String {
      /// Numeric Annotation Glyphs for moves, e.g. `$1`, `$2`, etc.
      case numericMove = #"^\$\d$"#
      /// Numeric Annotation Glyphs for positions, e.g. `$10`, `$11`, etc.
      case numericPosition = #"^\$\d{2,3}$"#
      /// Traditional suffix annotations, e.g. `!!`, `?!`, `□`, etc.
      case traditional = #"^[!?□]{1,2}$"#
    }

  }
}

// MARK: - Tokens
private extension PGNParser.MoveTextParser {
  private enum Token: Equatable {
    case number(String)
    case san(String)
    case annotation(String)
    case comment(String)
    case variationStart
    case variationEnd
    case result(String)
  }

  private enum TokenType {
    case none
    case number
    case san
    case annotation
    case variationStart
    case variationEnd
    case result
    case comment

    static func isNumber(_ character: Character) -> Bool {
      character.isWholeNumber || character == "."
    }

    static func isSAN(_ character: Character) -> Bool {
      character.isLetter || character.isWholeNumber || ["x", "+", "#", "=", "O", "o", "0", "-"].contains(character)
    }

    static func isAnnotation(_ character: Character) -> Bool {
      character.isWholeNumber || ["$", "?", "!", "□"].contains(character)
    }

    static func isVariationStart(_ character: Character) -> Bool {
      character == "("
    }

    static func isVariationEnd(_ character: Character) -> Bool {
      character == ")"
    }

    static func isResult(_ character: Character) -> Bool {
      ["1", "2", "/", "-", "0", "*"].contains(character)
    }

    static func isComment(_ character: Character) -> Bool {
      !character.isWhitespace
    }

    func isValid(character: Character) -> Bool {
      switch self {
      case .none: false
      case .number: Self.isNumber(character)
      case .san: Self.isSAN(character)
      case .annotation: Self.isAnnotation(character)
      case .variationStart: Self.isVariationStart(character)
      case .variationEnd: Self.isVariationEnd(character)
      case .result: Self.isResult(character)
      case .comment: Self.isComment(character)
      }
    }

    static func match(character: Character) -> Self {
      if isNumber(character) {
        .number
      } else if isSAN(character) {
        .san
      } else if isAnnotation(character) {
        .annotation
      } else if isVariationStart(character) {
        .variationStart
      } else if isVariationEnd(character) {
        .variationEnd
      } else if isResult(character) {
        .result
      } else if isComment(character) {
        .comment
      } else {
        .none
      }
    }

    func convert(_ text: String) -> Token? {
      switch self {
      case .none: nil
      case .number: .number(text.trimmingCharacters(in: .whitespaces))
      case .san: .san(text.trimmingCharacters(in: .whitespaces))
      case .annotation: .annotation(text.trimmingCharacters(in: .whitespaces))
      case .comment: .comment(text.trimmingCharacters(in: .whitespaces))
      case .variationStart: .variationStart
      case .variationEnd: .variationEnd
      case .result: .result(text.trimmingCharacters(in: .whitespaces))
      }
    }
  }
}
