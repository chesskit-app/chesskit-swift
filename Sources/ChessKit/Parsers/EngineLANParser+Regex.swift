//
//  EngineLANParser+Regex.swift
//  ChessKit
//

extension EngineLANParser {

    /// Contains useful regex strings for engine LAN parsing.
    struct Pattern {
        static let move = #"^([a-h][1-8]){2}[qrbn]?$"#
    }

}
