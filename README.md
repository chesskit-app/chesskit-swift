# ♟️ ChessKit

[![checks](https://github.com/chesskit-app/chesskit-swift/actions/workflows/checks.yaml/badge.svg)](https://github.com/chesskit-app/chesskit-swift/actions/workflows/checks.yaml) [![codecov](https://codecov.io/gh/chesskit-app/chesskit-swift/branch/master/graph/badge.svg?token=676EP0N8XF)](https://codecov.io/gh/chesskit-app/chesskit-swift)

A Swift package for efficiently implementing chess logic.

For a related Swift package that contains chess engines such as [Stockfish](https://stockfishchess.org), see [chesskit-engine](https://github.com/chesskit-app/chesskit-engine).

## Usage

1. Add `chesskit-swift` as a dependency
	* In an [app built in Xcode](https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app),
	* or [as a dependency to another Swift Package](https://www.swift.org/documentation/package-manager/#importing-dependencies).

2. Next, import `ChessKit` to use it in Swift code:
``` swift
import ChessKit

// ...

```

## Features

* Representation of chess elements
  * `Piece`: represents a single piece on the board, given by its color, type, and location on the board
  * `Square`: represents a square on the board
  * `Move`: represents a piece move, along with other metadata such as captures, annotations, and disambiguations
  * `Position`: represents a single position on the chess board
  * `Board`: validate and make moves in accordance with chess rules
  * `Game`: manage positions throughout a game and PGN tags
  * Special moves (castling, en passant): handled automatically by `Position` and `Board`
* Move validation
  * Implemented using highly performant `UInt64` [bitboards](https://www.chessprogramming.org/Bitboards).
* Move branching and variations
  * Implemented using a performant tree-like data structure `MoveTree`.
* Pawn promotion handling
* Game states (check, stalemate, checkmate, draws)
* Chess notation string parsing
  * `PGNParser`
  * `FENParser`
  * `SANParser`
  * `EngineLANParser` (for use with [UCI](https://www.wbec-ridderkerk.nl/html/UCIProtocol.html) engines)
* Eco Finder [(encyclopedia of chess openings)](https://en.wikipedia.org/wiki/Encyclopaedia_of_Chess_Openings)  
  Retrive an ECO using
  * PGN 
  * FEN
  * `Game`
  * `[Move]` 
  * `Position`
  * Opening Name

## Examples

* Create a board with the standard starting position:
``` swift
let board = Board()
```

* Create a board with a custom starting position using [FEN](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation):
``` swift
if let position = Position(fen: "rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2") {
    let board = Board(position: position)
    print(board)
}

// 8 ♜ ♞ ♝ ♛ ♚ ♝ ♞ ♜
// 7 ♟ ♟ · ♟ ♟ ♟ ♟ ♟
// 6 · · · · · · · ·
// 5 · · ♟ · · · · ·
// 4 · · · · ♙ · · ·
// 3 · · · · · ♘ · ·
// 2 ♙ ♙ ♙ ♙ · ♙ ♙ ♙
// 1 ♖ ♘ ♗ ♕ ♔ ♗ · ♖
//   a b c d e f g h
//
// (see `ChessKitConfiguration` for printing options)
```

* Move pieces on the board
``` swift
let board = Board()
// 8 ♜ ♞ ♝ ♛ ♚ ♝ ♞ ♜
// 7 ♟ ♟ ♟ ♟ ♟ ♟ ♟ ♟
// 6 · · · · · · · ·
// 5 · · · · · · · ·
// 4 · · · · · · · ·
// 3 · · · · · · · ·
// 2 ♙ ♙ ♙ ♙ ♙ ♙ ♙ ♙
// 1 ♖ ♘ ♗ ♕ ♔ ♗ ♘ ♖
//   a b c d e f g h

// move pawn at e2 to e4
board.move(pieceAt: .e2, to: .e4)
// 8 ♜ ♞ ♝ ♛ ♚ ♝ ♞ ♜
// 7 ♟ ♟ ♟ ♟ ♟ ♟ ♟ ♟
// 6 · · · · · · · ·
// 5 · · · · · · · ·
// 4 · · · · ♙ · · ·
// 3 · · · · · · · ·
// 2 ♙ ♙ ♙ ♙ · ♙ ♙ ♙
// 1 ♖ ♘ ♗ ♕ ♔ ♗ ♘ ♖
//   a b c d e f g h
```

* Check move legality
``` swift
let board = Board()
print(board.canMove(pieceAt: .a1, to: .a8)) // false
```

* Check legal moves
``` swift
let board = Board()
print(board.legalMoves(forPieceAt: .e2))    // [.e3, .e4]
```

* Parse [FEN](https://en.wikipedia.org/wiki/Forsyth–Edwards_Notation) into a `Position` object, [PGN](https://en.wikipedia.org/wiki/Portable_Game_Notation) (into `Game`), or [SAN](https://en.wikipedia.org/wiki/Algebraic_notation_(chess)) (into `Move`).
``` swift
// parse FEN using Position initializer
let fen = "rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2"
let position = Position(fen: fen)

// convert Position to FEN string
let fenString = position.fen

// parse PGN using Game initializer
let game = Game(pgn: "1. e4 e5 2. Nf3")

// convert Game to PGN string
let pgnString = game.pgn

// parse the move text "e4" from the starting position
let move = Move(san: "e4", in: .standard)

// convert Move to SAN string
let sanString = move.san
```

* Eco Finder
``` swift
let ecoFinder = try? EcoFinder()

let fen = "rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2" // Sicilian Defense
ecoFinder.getEco(for: fen, positionType: .FEN)
ecoFinder.getEco(by: "King's Pawn Game")

let pgn = "1. e4 e5" // King's Pawn Game
try? self.ecoFinder.searchEco(for: pgn)

```

## License

`ChessKit` is distributed under the [MIT License](https://github.com/chesskit-app/chesskit-swift/blob/master/LICENSE).
