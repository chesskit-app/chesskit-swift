//
//  BoardSquare.swift
//  ChessKit
//

public enum Square: Equatable, CaseIterable {
    /// The file on the chess board, from a to h.
    public enum File: String, CaseIterable  {
        case a, b, c, d, e, f, g, h
        
        /// The number corresponding to the file.
        ///
        /// For example:
        /// ```
        /// Square.File.a.number // 1
        /// Square.File.h.number // 8
        /// ```
        ///
        public var number: Int {
            File.allCases.firstIndex(of: self)! + 1
        }
        
        /// Initialize a file from a number from 1 through 8.
        ///
        /// - parameter number: The number of the file to set.
        ///
        /// If an invalid number is passed, i.e. less than 1 or
        /// greater than 8, the file is set to `.a`.
        ///
        /// See also `Square.File.number`.
        ///
        public init(_ number: Int) {
            switch number {
            case 1:   self = .a
            case 2:   self = .b
            case 3:   self = .c
            case 4:   self = .d
            case 5:   self = .e
            case 6:   self = .f
            case 7:   self = .g
            case 8:   self = .h
            default:  self = .a
            }
        }
    }

    /// The rank on the chess board, from 1 to 8.
    public struct Rank: ExpressibleByIntegerLiteral, Equatable, Hashable {
        /// The possible range of Rank numbers.
        public static let range = 1...8
        
        /// The integer value of the Rank.
        public var value: Int
        
        /// Initialize a Rank with a provided integer value.
        public init(_ value: Int) {
            self.value = value.bounded(by: Rank.range)
        }
        
        /// Initialize a Rank with a provided integer literal.
        public init(integerLiteral value: IntegerLiteralType) {
            self.init(value)
        }
    }

    // MARK: - Squares
    
    case a1, a2, a3, a4, a5, a6, a7, a8
    case b1, b2, b3, b4, b5, b6, b7, b8
    case c1, c2, c3, c4, c5, c6, c7, c8
    case d1, d2, d3, d4, d5, d6, d7, d8
    case e1, e2, e3, e4, e5, e6, e7, e8
    case f1, f2, f3, f4, f5, f6, f7, f8
    case g1, g2, g3, g4, g5, g6, g7, g8
    case h1, h2, h3, h4, h5, h6, h7, h8
    
    // MARK: - Initializer
    
    /// Initializes a board square from the given notation string.
    ///
    /// - parameter notation: The notation of the square, e.g. `"a1"`.
    ///
    public init(_ notation: String) {
        let file = File.allCases.filter { $0.rawValue == notation.prefix(1) }.first ?? .a
        let rank = Rank(Int(notation.suffix(1)) ?? 1)
        self.init(file, rank)
    }
    
    /// Initializes a board square from the provided file and rank.
    ///
    /// - parameter file: The file (column) of the square, from `a` to `h`.
    /// - parameter rank: The rank (row) of the square, from `1` to `8`.
    ///
    init(_ file: File, _ rank: Rank) {
        switch (file, rank) {
        case (.a, 1):   self = .a1
        case (.a, 2):   self = .a2
        case (.a, 3):   self = .a3
        case (.a, 4):   self = .a4
        case (.a, 5):   self = .a5
        case (.a, 6):   self = .a6
        case (.a, 7):   self = .a7
        case (.a, 8):   self = .a8
        case (.b, 1):   self = .b1
        case (.b, 2):   self = .b2
        case (.b, 3):   self = .b3
        case (.b, 4):   self = .b4
        case (.b, 5):   self = .b5
        case (.b, 6):   self = .b6
        case (.b, 7):   self = .b7
        case (.b, 8):   self = .b8
        case (.c, 1):   self = .c1
        case (.c, 2):   self = .c2
        case (.c, 3):   self = .c3
        case (.c, 4):   self = .c4
        case (.c, 5):   self = .c5
        case (.c, 6):   self = .c6
        case (.c, 7):   self = .c7
        case (.c, 8):   self = .c8
        case (.d, 1):   self = .d1
        case (.d, 2):   self = .d2
        case (.d, 3):   self = .d3
        case (.d, 4):   self = .d4
        case (.d, 5):   self = .d5
        case (.d, 6):   self = .d6
        case (.d, 7):   self = .d7
        case (.d, 8):   self = .d8
        case (.e, 1):   self = .e1
        case (.e, 2):   self = .e2
        case (.e, 3):   self = .e3
        case (.e, 4):   self = .e4
        case (.e, 5):   self = .e5
        case (.e, 6):   self = .e6
        case (.e, 7):   self = .e7
        case (.e, 8):   self = .e8
        case (.f, 1):   self = .f1
        case (.f, 2):   self = .f2
        case (.f, 3):   self = .f3
        case (.f, 4):   self = .f4
        case (.f, 5):   self = .f5
        case (.f, 6):   self = .f6
        case (.f, 7):   self = .f7
        case (.f, 8):   self = .f8
        case (.g, 1):   self = .g1
        case (.g, 2):   self = .g2
        case (.g, 3):   self = .g3
        case (.g, 4):   self = .g4
        case (.g, 5):   self = .g5
        case (.g, 6):   self = .g6
        case (.g, 7):   self = .g7
        case (.g, 8):   self = .g8
        case (.h, 1):   self = .h1
        case (.h, 2):   self = .h2
        case (.h, 3):   self = .h3
        case (.h, 4):   self = .h4
        case (.h, 5):   self = .h5
        case (.h, 6):   self = .h6
        case (.h, 7):   self = .h7
        case (.h, 8):   self = .h8
        default:        self = .a1
        }
    }
    
    // MARK: - Components
    
    /// The file (column) of the given square, from `a` through `h`.
    var file: File {
        switch self {
        case .a1, .a2, .a3, .a4, .a5, .a6, .a7, .a8: return .a
        case .b1, .b2, .b3, .b4, .b5, .b6, .b7, .b8: return .b
        case .c1, .c2, .c3, .c4, .c5, .c6, .c7, .c8: return .c
        case .d1, .d2, .d3, .d4, .d5, .d6, .d7, .d8: return .d
        case .e1, .e2, .e3, .e4, .e5, .e6, .e7, .e8: return .e
        case .f1, .f2, .f3, .f4, .f5, .f6, .f7, .f8: return .f
        case .g1, .g2, .g3, .g4, .g5, .g6, .g7, .g8: return .g
        case .h1, .h2, .h3, .h4, .h5, .h6, .h7, .h8: return .h
        }
    }
    
    /// The rank (row) of the given square, from `1` to `8`.
    var rank: Rank {
        switch self {
        case .a1, .b1, .c1, .d1, .e1, .f1, .g1, .h1: return 1
        case .a2, .b2, .c2, .d2, .e2, .f2, .g2, .h2: return 2
        case .a3, .b3, .c3, .d3, .e3, .f3, .g3, .h3: return 3
        case .a4, .b4, .c4, .d4, .e4, .f4, .g4, .h4: return 4
        case .a5, .b5, .c5, .d5, .e5, .f5, .g5, .h5: return 5
        case .a6, .b6, .c6, .d6, .e6, .f6, .g6, .h6: return 6
        case .a7, .b7, .c7, .d7, .e7, .f7, .g7, .h7: return 7
        case .a8, .b8, .c8, .d8, .e8, .f8, .g8, .h8: return 8
        }
    }
    
    /// The notation for the given square.
    public var notation: String {
        file.rawValue + "\(rank.value)"
    }
    
    // MARK: - Color
    
    /// Represents the possible colors of each board square.
    public enum Color: CaseIterable {
        case light, dark
    }
    
    /// The color of the square on the board, either light or dark.
    public var color: Color {
        if (file.number % 2 == 0 && rank.value % 2 == 0) || (file.number % 2 != 0 && rank.value % 2 != 0) {
            return .dark
        } else {
            return .light
        }
    }
}
