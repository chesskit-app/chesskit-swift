//
//  SANParser+Regex.swift
//  ChessKit
//

extension SANParser {

    /// Contains useful regex strings for SAN parsing.
    struct Regex {
        static let full = #"(([Oo0]-[Oo0](-[Oo0])?|[KQRBN]?[a-h]?[1-8]?x?[a-h][1-8](\=[QRBN])?[+#]?))"#

        // piece kinds
        static let pawnFile = #"^[a-h]"#
        static let pieceKind = #"^[KQRBN]"#

        // castling
        static let shortCastle = #"^[Oo0]-[Oo0]\+?#?$"#
        static let longCastle = #"^[Oo0]-[Oo0]-[Oo0]\+?#?$"#

        // disambiguation
        static let disambiguation = #"[a-h]?[1-8]?(?=([a-h][1-8])$)"#
        static let rank = #"^[1-8]$"#
        static let file = #"^[a-h]$"#
        static let square = #"^[a-h][1-8]$"#

        // other
        static let promotion = #"\=[QRBN]"#
        static let targetSquare = #"([a-h][1-8])(?!([a-h][1-8]))"#
    }

}
