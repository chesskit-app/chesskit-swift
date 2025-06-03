//
//  PGNParser+Regex.swift
//  ChessKit
//

extension PGNParser {

  /// Contains useful regex strings for PGN parsing.
  struct Pattern {
    // tag pair components
    static let tags = #"\[[^\]]+\]"#
    static let tagPair = #"\[([^"]+?)\s"([^"]+)"\]"#

    // move text
    static let moveText = #"\d{1,}\.{1,3}\s?(([Oo0]-[Oo0](-[Oo0])?|[KQRBN]?[a-h]?[1-8]?x?[a-h][1-8](\=[QRBN])?[+#]?)([\?!]{1,2})?(\s?\$\d)?(\s?\{.+?\})?(\s(1-0|0-1|1\/2-1\/2|\*)\s*$)?\s?){1,2}"#
    static let moveNumber = #"^\d{1,}"#
    static let singleMove = "\(SANParser.Pattern.full)(\\s?\(annotation))?(\\s?\(comment))?"
    static let result = #"(\s(1-0|0-1|1\/2-1\/2|\*)\s?){1}$"#

    // move pair components
    static let annotation = #"\$\d"#
    static let comment = #"\{.+?\}"#
  }

}
