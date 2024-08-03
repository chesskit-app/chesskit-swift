//
//  FENParser.swift
//  ChessKit
//

/// Parses and converts the Forsyth–Edwards Notation (FEN)
/// of a chess position.
///
/// For example, the standard starting position is represented as:
/// ```
/// "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
/// ```
public enum FENParser {

    /// Number of components in FEN
    /// 1. Piece placement
    /// 2. Side to move
    /// 3. Castling ability
    /// 4. En Passant
    /// 5. Halfmoves
    /// 6. Fullmoves
    private static let componentCount = 6

    /// Parses a FEN string and returns a position.
    ///
    /// - parameter fen: The FEN string of a chess position.
    /// - returns: A Swift representation of the chess position,
    ///     or `nil` if the FEN is invalid.
    ///
    public static func parse(fen: String) -> Position? {
        let separatedFen = fen.components(separatedBy: .whitespaces)

        guard separatedFen.count == FENParser.componentCount else {
            return nil
        }

        // piece placement

        let piecePlacementByRank = separatedFen[0]
            .components(separatedBy: "/")
            .enumerated()

        let pieces = piecePlacementByRank.compactMap { (index, rankString) -> [Piece]? in
            let piecesInRank = rankString.map(String.init)
            let rank = Square.Rank(Square.Rank.range.upperBound - index)

            let digits = Square.Rank.range.map(String.init)
            var fileNumber = 0

            return piecesInRank.compactMap { (s: String) -> Piece? in
                if digits.contains(s), let numberOfEmptySpaces = Int(s) {
                    fileNumber += numberOfEmptySpaces
                    return nil
                } else {
                    fileNumber += 1
                    let file = Square.File(fileNumber)
                    let square = Square(file, rank)
                    return Piece(fen: s, square: square)
                }
            }
        }.flatMap { $0 }

        // side to move

        let sideToMove = Piece.Color(rawValue: separatedFen[1]) ?? .white

        // castling ability

        var legalCastlings: [Castling] = []
        let castlingAbility = separatedFen[2].map(String.init)

        if castlingAbility.contains("k") { legalCastlings.append(.bK) }
        if castlingAbility.contains("K") { legalCastlings.append(.wK) }
        if castlingAbility.contains("q") { legalCastlings.append(.bQ) }
        if castlingAbility.contains("Q") { legalCastlings.append(.wQ) }

        // en passant target square

        var enPassant: EnPassant?

        let ep = separatedFen[3]

        if ep != "-" && ep.count == 2 {
            let epFile = Square.File(rawValue: ep.map(String.init)[0])
            let epRank = Int(ep.map(String.init)[1])

            if let epRank, epRank == 3, let epFile = epFile {
                enPassant = EnPassant(pawn: Piece(.pawn, color: .white, square: Square(epFile, Square.Rank(epRank + 1))))
            } else if let epRank, epRank == 6, let epFile {
                enPassant = EnPassant(pawn: Piece(.pawn, color: .black, square: Square(epFile, Square.Rank(epRank - 1))))
            }
        }

        // clock

        var clock = Clock()

        if let halfmove = Int(separatedFen[4]), let fullmove = Int(separatedFen[5]) {
            clock = Clock(halfmoves: halfmove, fullmoves: fullmove)
        }

        // final position

        return Position(
            pieces: pieces,
            sideToMove: sideToMove,
            legalCastlings: LegalCastlings(legal: legalCastlings),
            enPassant: enPassant,
            clock: clock
        )
    }

    /// Converts a ``Position`` object into a FEN string.
    ///
    /// - parameter position: The chess position to convert.
    /// - returns: A string containing the FEN of `position`.
    ///
    public static func convert(position: Position) -> String {
        var fen = ""

        // piece position

        for r in Square.Rank.range.reversed() {
            let rank = Square.Rank(r)
            var emptySpaceCounter = 0

            for file in Square.File.allCases {
                if let piece = position.piece(at: Square(file, rank)) {
                    if emptySpaceCounter > 0 {
                        fen += "\(emptySpaceCounter)"
                    }

                    fen += piece.fen
                    emptySpaceCounter = 0
                } else {
                    emptySpaceCounter += 1
                }
            }

            if emptySpaceCounter > 0 {
                fen += "\(emptySpaceCounter)"
                emptySpaceCounter = 0
            }

            fen += "/"
        }

        // remove extra `/`
        fen.removeLast()

        fen += " "

        // side to move

        fen += position.sideToMove.rawValue + " "

        // castling ability

        fen += position.legalCastlings.fen + " "

        // en passant

        if let enPassant = position.enPassant {
            fen += "\(enPassant.captureSquare) "
        } else {
            fen += "- "
        }

        // clock

        fen += "\(position.clock.halfmoves) \(position.clock.fullmoves)"

        return fen
    }

}
