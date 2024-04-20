//
//  ChessKitConfiguration.swift
//  ChessKit
//

/// Stores configuration options for the `ChessKit` package.
public struct ChessKitConfiguration {

    /// Configuration options for printing `Board` and `Position` objects, useful
    /// for debugging.
    public static var printOptions: PrintOptions = .init()

    public struct PrintOptions {
        /// Whether to print pieces as letters (`letter`) or unicode graphics (`graphic`)
        /// when printing `Board` and `Position` objects.
        ///
        /// The default value is `graphic`.
        public var mode: PrintMode = .graphic

        /// Whether to print rank and file labels
        /// when printing `Board` and `Position` objects.
        ///
        /// The default value is `graphic`.
        public var showCoordinates = true

        /// ChessKit `printMode` options.
        public enum PrintMode {
            /// Print pieces as unicode graphic characters, e.g. ♟, ♞, ♝, ♜, ♛, ♚.
            case graphic
            /// Print pieces as FEN letters, e.g. P, N, B, R, Q, K.
            ///
            /// Uppercase letters are white pieces and lowercase letters are black pieces.
            case letter
        }
    }

    /// Whether to print pieces as letters (`letter`) or unicode graphics (`graphic`)
    /// when printing `Board` and `Position` objects.
    ///
    /// The default value is `graphic`.
    @available(*, deprecated, renamed: "printOptions.mode")
    public static var printMode: PrintOptions.PrintMode {
        get { printOptions.mode }
        set { printOptions.mode = newValue }
    }

}

