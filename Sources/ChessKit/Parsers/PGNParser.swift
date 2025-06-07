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
  /// - returns: A Swift representation of the chess game,
  ///     or `nil` if the PGN is invalid.
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

    let moveTextTokens = try MoveTextParser.tokenize(
      moveText: moveTextLines.joined(separator: " ")
    )

    var game = try MoveTextParser.parse(tokens: moveTextTokens, startingWith: startingPosition)
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
    case tooManyLineBreaks
    case invalidSetUpOrFEN

    // tags
    case invalidTagFormat
    case mismatchedTagBrackets
    case stringNotFound
    case symbolNotFound
    case unexpectedCharacter(String)

    // move text
    case invalidAnnotation(String)
    case invalidMove(String)
    case invalidResult(String)
    case unexpectedMoveTextToken
    case unpairedCommentDelimiter
    case unpairedVariationDelimiter
  }
}

private enum PGNTagParser {

  /// Represents a tag pair token.
  ///
  /// The format of a tag pair is:
  /// `<open bracket> <symbol> "<string>" <close bracket>`
  /// with 0 or more whitespaces between tokens.
  enum Token: Equatable {
    case openBracket
    case symbol(String)
    case string(String)
    case closeBracket
  }

  private struct TokenizationState {
    var bracketOpened = false
    var quoteOpened = false
  }

  private static func tokenize(tags: String) throws(PGNParser.Error) -> [Token] {
    let inlineTags = tags.components(separatedBy: .newlines).joined(separator: "")
    var iterator = inlineTags.makeIterator()

    var tokens = [Token]()
    var state = TokenizationState()
    var symbol = ""
    var string = ""

    while let c = iterator.next() {
      if c == "[" {
        tokens.append(.openBracket)
      } else if c == "]" {
        tokens.append(.closeBracket)
      } else if c.isOpenQuote && !state.quoteOpened {
        if !symbol.isEmpty {
          tokens.append(.symbol(symbol))
          symbol = ""
        }
        state.quoteOpened = true
      } else if c.isCloseQuote && state.quoteOpened {
        if !string.isEmpty {
          tokens.append(.string(string))
          string = ""
        }
        state.quoteOpened = false
      } else {
        if c.isWhitespace && !state.quoteOpened {
          if !symbol.isEmpty {
            tokens.append(.symbol(symbol))
            symbol = ""
          }
        } else if state.quoteOpened {
          string += String(c)
        } else {
          if c.isLetter || c.isNumber || c == "_" {
            symbol += String(c)
          } else {
            throw .unexpectedCharacter(String(c))
          }
        }
      }
    }

    return tokens
  }

  private static func parse(tags: String) throws(PGNParser.Error) -> [String: String] {
    let tokens = try tokenize(tags: tags)

    guard tokens.count % 4 == 0 else {
      throw .invalidTagFormat
    }

    typealias TokenGroup = (Token, Token, Token, Token)
    let groupedTokens: [TokenGroup] = stride(from: 0, to: tokens.count, by: 4).map {
      (tokens[$0], tokens[$0 + 1], tokens[$0 + 2], tokens[$0 + 3])
    }

    var parsedTags = [(String, String)]()

    for token in groupedTokens {
      guard token.0 == .openBracket && token.3 == .closeBracket else {
        throw .mismatchedTagBrackets
      }

      guard case let .symbol(symbol) = token.1 else {
        throw .symbolNotFound
      }

      guard case let .string(string) = token.2 else {
        throw .stringNotFound
      }

      parsedTags.append((symbol, string))
    }

    return Dictionary<String, String>(parsedTags) { first, _ in first }
  }

  static func gameTags(from tagString: String) throws(PGNParser.Error) -> Game.Tags {
    var gameTags = Game.Tags()

    try parse(tags: tagString).forEach { key, value in
      switch key.lowercased() {
      case "event": gameTags.event = value
      case "site": gameTags.site = value
      case "date": gameTags.date = value
      case "round": gameTags.round = value
      case "white": gameTags.white = value
      case "black": gameTags.black = value
      case "result": gameTags.result = value
      case "annotator": gameTags.annotator = value
      case "plyCount": gameTags.plyCount = value
      case "timeControl": gameTags.timeControl = value
      case "time": gameTags.time = value
      case "termination": gameTags.termination = value
      case "mode": gameTags.mode = value
      case "fen": gameTags.fen = value
      case "setUp": gameTags.setUp = value
      default: gameTags.other[key] = value
      }
    }

    return gameTags
  }

}

private extension Character {

  var isOpenQuote: Bool {
    ["\"", "“"].contains(self)
  }

  var isCloseQuote: Bool {
    ["\"", "”"].contains(self)
  }

}

private enum MoveTextParser {

  public enum Token: Equatable {
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

    func convert(_ text: String) -> MoveTextParser.Token? {
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

  static func tokenize(moveText: String) throws(PGNParser.Error) -> [Token] {
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

  static func parse(
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
    var variationStack = Stack<MoveTree.Index>() {
      didSet {
        print(variationStack)
      }
    }

    while let token = iterator.next() {
      print("\(token) ; \(currentMoveIndex)")
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
        var moveAssessment: Move.Assessment?

        if let notation = firstMatch(in: annotation, for: #"^[!?□]+$"#) {
          moveAssessment = .init(notation: notation)
        } else if let rawValue = firstMatch(in: annotation, for: #"^\$\d$"#) {
          moveAssessment = .init(rawValue: rawValue)
        } else if let _ = firstMatch(in: annotation, for: #"^\$\d{2,3}$"#) {
          // position assessment, TBD
          // game.annotate(positionAt: currentMoveIndex, assessment: ...)
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

  private static func firstMatch(in string: String, for pattern: String) -> String? {
    let matches = try? NSRegularExpression(pattern: pattern)
      .matches(in: string, range: NSRange(0..<string.utf16.count))

    if let match = matches?.first {
      return NSString(string: string).substring(with: match.range)
    } else {
      return nil
    }
  }

  private struct Stack<T>: CustomStringConvertible {
    var description: String {
      var result = ""
      var node = root
      while let value = node?.value {
        result += "\(value),"
        node = node?.child
      }
      return result
    }

    private var root: Node<T>?
    private var top: Node<T>?

    private class Node<V> {
      let value: V
      var parent: Node?
      var child: Node?

      init(_ value: V) {
        self.value = value
      }
    }

    mutating func push(_ value: T) {
      if root == nil {
        root = Node(value)
        top = root
      } else {
        let newNode = Node(value)
        newNode.parent = top
        top?.child = newNode
        top = newNode
      }
    }

    mutating func pop() -> T? {
      let value = top?.value
      top?.child = nil
      top = top?.parent
      return value
    }
  }

}
