//
//  PGNParser+Tags.swift
//  ChessKit
//

extension PGNParser {
  enum PGNTagParser {

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
