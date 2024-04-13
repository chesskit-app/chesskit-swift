//
//  ChessKitConfiguration.swift
//  ChessKit
//

/// Stores configuration options for the `ChessKit` package.
public struct ChessKitConfiguration {

    /// ChessKit `printMode` options.
    public enum PrintMode {
        /// Print pieces as unicode graphic characters, e.g. ♟, ♞, ♝, ♜, ♛, ♚.
        case graphic
        /// Print pieces as FEN letters, e.g. P, N, B, R, Q, K.
        ///
        /// Uppercase letters are white pieces and lowercase letters are black pieces.
        case letter
    }

    /// Whether to print pieces as letters (`letter`) or unicode graphics (`graphic`)
    /// when printing `Board` and `Position` objects; useful for debugging.
    ///
    /// The default value is `graphic`.
    public static var printMode: PrintMode = .graphic

}

