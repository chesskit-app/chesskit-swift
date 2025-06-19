//
//  Command.swift
//  ChessKit
//

enum Command: Equatable {
  case exit
  case board
  case clear
  case help
  case position
  case reset(fen: String? = nil)
  case move(sans: [String])

  static func match(_ input: String) -> Command? {
    let input = input.split(separator: " ").map(String.init)
    guard let command = input.first else { return nil }

    let args = input.count > 1 ? Array(input.dropFirst()) : [String]()

    switch command {
    case "exit", "quit", "q":
      return .exit
    case "board", "b":
      return .board
    case "clear", "c":
      return .clear
    case "help", "h":
      return .help
    case "position", "p":
      return .position
    case "reset", "r":
      let fen = args.joined(separator: " ")
      if fen.isEmpty {
        return .reset(fen: nil)
      } else {
        return .reset(fen: fen)
      }
    case "move", "m":
      return .move(sans: args)
    default:
      return nil
    }
  }
}
