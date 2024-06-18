//
//  Piece.swift
//  ChessKit
//

/// Represents a piece on the chess board.
public struct Piece: Equatable, Hashable, Sendable {

    /// Represents the color of a piece.
    public enum Color: String, CaseIterable, Sendable {
        case black = "b", white = "w"

        /// The opposite color of the given color.
        public var opposite: Color {
            self == .black ? .white : .black
        }

        /// Toggles to the opposite color value.
        public mutating func toggle() {
            self = self.opposite
        }
    }

    /// Represents the type of piece.
    public enum Kind: String, CaseIterable, Sendable {
        case pawn = ""
        case knight = "N", bishop = "B", rook = "R", queen = "Q", king = "K"

        /// The notation of the given piece kind.
        public var notation: String {
            switch self {
            case .pawn:   ""
            case .bishop: "B"
            case .knight: "N"
            case .rook:   "R"
            case .queen:  "Q"
            case .king:   "K"
            }
        }

    }

    /// The color of the piece.
    public var color: Color
    /// The kind of piece, e.g. `.pawn`.
    public var kind: Kind
    /// The square where this piece is located on the board.
    public var square: Square

    /// Initializes a chess piece with the given kind, color, and square.
    ///
    /// - parameter kind: The kind of piece, e.g. `.pawn`.
    /// - parameter color: The color of the piece, e.g. `.white`.
    /// - parameter square: The square the piece is located on, e.g. `.a1`.
    ///
    public init(_ kind: Kind, color: Color, square: Square) {
        self.kind = kind
        self.color = color
        self.square = square
    }

    /// Initializes a chess piece from its FEN notation.
    ///
    /// - parameter fen: The Forsyth–Edwards Notation of a piece kind
    ///     and color, e.g. `"p"`.
    /// - parameter square: The square the piece is located on, e.g. `.a1`.
    ///
    init?(fen: String, square: Square) {
        switch fen {
        case "p": self = Piece(.pawn,   color: .black, square: square)
        case "b": self = Piece(.bishop, color: .black, square: square)
        case "n": self = Piece(.knight, color: .black, square: square)
        case "r": self = Piece(.rook,   color: .black, square: square)
        case "q": self = Piece(.queen,  color: .black, square: square)
        case "k": self = Piece(.king,   color: .black, square: square)
        case "P": self = Piece(.pawn,   color: .white, square: square)
        case "B": self = Piece(.bishop, color: .white, square: square)
        case "N": self = Piece(.knight, color: .white, square: square)
        case "R": self = Piece(.rook,   color: .white, square: square)
        case "Q": self = Piece(.queen,  color: .white, square: square)
        case "K": self = Piece(.king,   color: .white, square: square)
        default:  return nil
        }
    }

    /// The FEN representation of the piece.
    ///
    /// Note: This value does not convey any information regarding
    /// the piece's location on the board (only kind and color).
    var fen: String {
        switch (color, kind) {
        case (.black, .pawn):   "p"
        case (.black, .bishop): "b"
        case (.black, .knight): "n"
        case (.black, .rook):   "r"
        case (.black, .queen):  "q"
        case (.black, .king):   "k"
        case (.white, .pawn):   "P"
        case (.white, .bishop): "B"
        case (.white, .knight): "N"
        case (.white, .rook):   "R"
        case (.white, .queen):  "Q"
        case (.white, .king):   "K"
        }
    }

    var graphic: String {
        switch (color, kind) {
        case (.black, .pawn):   "♟\u{FE0E}"
        case (.black, .bishop): "♝"
        case (.black, .knight): "♞"
        case (.black, .rook):   "♜"
        case (.black, .queen):  "♛"
        case (.black, .king):   "♚"
        case (.white, .pawn):   "♙"
        case (.white, .bishop): "♗"
        case (.white, .knight): "♘"
        case (.white, .rook):   "♖"
        case (.white, .queen):  "♕"
        case (.white, .king):   "♔"
        }
    }

}
