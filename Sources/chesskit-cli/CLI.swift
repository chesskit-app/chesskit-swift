//
//  CLI.swift
//  ChessKit
//

import ChessKit
import Dye

class CLI {

  // MARK: Properties

  private let help =
    """
    USAGE:
      b, board          Print the current position as a visual chess board
      c, clear          Clear the visible area of the console
      m, move <san>...  Execute moves on the board using standard algebraic notation
      h, help           Print this help message
      p, position       Print the current position as FEN
      r, reset [fen]    Resets the board, optionally to a custom FEN position (standard position is the default)
      q, quit           Ends ChessKit session

    """

  private var board: Board
  private var output: OutputStream

  // MARK: Initializer

  init(board: Board = Board()) {
    self.board = board
    output = .standardOutput()
  }

  // MARK: Public

  func startUp() {
    write("Starting ChessKit ♞...", as: .success)

    write("\n")
    write("\(board)")
    write("\n\n")
    write(help)
    write("\n")
  }

  @discardableResult
  func process(input: String) -> Command? {
    output.clear()
    let command = Command.match(input)

    switch command {
    case nil:
      write("Unrecognized command ", as: .error)
      write("\(input)\n")
    case .quit:
      write("Goodbye\n", as: .success)
    case .board:
      write("\(board)\n")
    case .clear:
      print("\u{001B}[2J\u{001B}[H", terminator: "")
    case .help:
      write(help)
    case .position:
      write("\(FENParser.convert(position: board.position))\n", as: .info)
    case let .reset(fen):
      if let fen {
        if let position = FENParser.parse(fen: fen) {
          board = .init(position: position)
          write("\(board)\n")
        } else {
          write("Invalid FEN\n", as: .error)
        }
      } else {
        board = .init()
        write("\(board)\n")
      }
    case let .move(sans):
      sans.forEach {
        if let move = SANParser.parse(move: $0, in: board.position) {
          board.move(pieceAt: move.start, to: move.end)
          write("Moved ", as: .success)
          write("from ")
          write("\(move.start) ", as: .info)
          write("to ")
          write("\(move.end)\n", as: .info)
        } else {
          write("Invalid move ", as: .error)
          write("\($0)\n", as: .info)
        }
      }
    }

    return command
  }

  // MARK: Private

  private enum MessageType {
    case error
    case info
    case success

    var style: OutputStream.Style {
      switch self {
      case .error, .success: .bold
      case .info: []
      }
    }

    var foreground: OutputStream.Color {
      switch self {
      case .error: .intenseRed
      case .info: .intenseCyan
      case .success: .intenseGreen
      }
    }
  }

  private func write(_ string: String, as type: MessageType? = nil) {
    output.color.foreground = type?.foreground
    output.style = type?.style ?? []
    output.write(string)
    output.clear()
  }

}
