//
//  Castling.swift
//  ChessKit
//

/// Structure that captures legal castling moves.
struct LegalCastlings: Hashable, Sendable {

  private var legal: [Castling]

  /// Initialize a `LegalCastlings` struct with an
  /// array of legal castling moves.
  ///
  /// - parameter legal: An array of legal ``Castling`` moves.
  ///
  init(legal: [Castling] = [.bK, .wK, .bQ, .wQ]) {
    self.legal = legal
  }

  /// Removes any castling moves associated with `piece` from the
  /// list of legal castlings.
  ///
  /// - parameter piece: The piece for which to invalidate castlings.
  /// Must be either a `.king` or `.rook` piece.
  ///
  /// For example, if a king has moved, pass the king piece to this
  /// method to remove any castlings associated with that king.
  mutating func invalidateCastling(for piece: Piece) {
    if piece.kind == .king {
      legal.removeAll { $0.color == piece.color }
    } else if piece.kind == .rook {
      legal.removeAll { $0.color == piece.color && $0.rookStart == piece.square }
    }
  }

  /// Checks if a given castling is currently legal.
  ///
  /// - parameter castling: The castling move to check for legality.
  /// - returns: Whether or not the provided `castling` is legal.
  ///
  func contains(_ castling: Castling) -> Bool {
    legal.contains(castling)
  }

  /// The FEN representation of the legal castlings.
  ///
  /// Examples: `KQkq`, `QK`, `Qkq`, `k`, `-`
  var fen: String {
    legal.isEmpty ? "-" : legal.map(\.fen).sorted().joined()
  }

}

/// Represents a castling move in a standard chess game.
///
/// Contains various characteristics of the castling move
/// such as king and rook start and end squares and notation.
public struct Castling: Hashable, Sendable {

  /// Kingside castle for black.
  static let bK = Castling(side: .king, color: .black)
  /// Kingside castle for white.
  static let wK = Castling(side: .king, color: .white)
  /// Queenside castle for black.
  static let bQ = Castling(side: .queen, color: .black)
  /// Queenside castle for white.
  static let wQ = Castling(side: .queen, color: .white)

  /// Represents the side of the board from which castling an occur.
  /// Either `king` or `queen`.
  enum Side: CaseIterable, Sendable {
    case king, queen

    var notation: String {
      switch self {
      case .king: "O-O"
      case .queen: "O-O-O"
      }
    }
  }

  /// The side of the board for which this castling object represents.
  var side: Side
  /// The color of the king and rook castling.
  var color: Piece.Color

  /// The squares that the king will pass through when castling.
  var squares: [Square] {
    switch color {
    case .white: (side == .queen) ? [.c1, .d1] : [.f1, .g1]
    case .black: (side == .queen) ? [.c8, .d8] : [.f8, .g8]
    }
  }

  /// The squares between the king and rook that must be clear for castling.
  var path: [Square] {
    switch color {
    case .white: (side == .queen) ? [.b1, .c1, .d1] : [.f1, .g1]
    case .black: (side == .queen) ? [.b8, .c8, .d8] : [.f8, .g8]
    }
  }

  /// The starting square of the king, depending on the color.
  public var kingStart: Square {
    switch color {
    case .white: .e1
    case .black: .e8
    }
  }

  /// The ending square of the king, depending on the castle side and color.
  public var kingEnd: Square {
    switch color {
    case .white: (side == .queen) ? .c1 : .g1
    case .black: (side == .queen) ? .c8 : .g8
    }
  }

  /// The starting square of the rook, depending on the castle side and color.
  public var rookStart: Square {
    switch color {
    case .white: (side == .queen) ? .a1 : .h1
    case .black: (side == .queen) ? .a8 : .h8
    }
  }

  /// The ending square of the rook, depending on the castle side and color.
  public var rookEnd: Square {
    switch color {
    case .white: (side == .queen) ? .d1 : .f1
    case .black: (side == .queen) ? .d8 : .f8
    }
  }

  /// The FEN representation of the castling.
  ///
  /// Possible values: `K`, `Q`, `k`, or `q`
  var fen: String {
    switch color {
    case .white: (side == .queen) ? "Q" : "K"
    case .black: (side == .queen) ? "q" : "k"
    }
  }
}
