//
//  Game.swift
//  ChessKit
//

import Foundation

/// Represents a chess game.
///
/// This object is the entry point for interacting with a full
/// chess game within `ChessKit`. It provides methods for
/// making moves and publishes the played moves in an observable way.
public struct Game: Hashable, Sendable {

  // MARK: - Properties

  /// The move tree representing all moves made in the game.
  public private(set) var moves: MoveTree
  /// The move tree index of the starting position in the game.
  public private(set) var startingIndex: MoveTree.Index
  /// A dictionary of every position in the game, keyed by move index.
  public private(set) var positions: [MoveTree.Index: Position]
  /// Contains the tag pairs for this game.
  public var tags: Tags

  /// The starting position of the game.
  public var startingPosition: Position? {
    positions[startingIndex]
  }

  // MARK: - Initializer

  /// Initialize a game with a starting position.
  ///
  /// - parameter position: The starting position of the game.
  /// - parameter tags: The PGN tags associated with this game.
  ///
  /// Defaults to the starting position.
  public init(startingWith position: Position = .standard, tags: Tags? = nil) {
    moves = MoveTree()
    let startingIndex = position.sideToMove == .white ? MoveTree.Index.minimum : .minimum.next
    self.startingIndex = startingIndex
    positions = [startingIndex: position]
    self.tags = tags ?? .init()

    moves.minimumIndex = startingIndex
  }

  /// Initialize a game with a PGN string.
  ///
  /// - parameter pgn: A string containing a PGN representation of
  /// a game.
  ///
  /// This initalizer fails if the PGN is invalid.
  public init?(pgn: String) {
    guard let parsed = PGNParser.parse(game: pgn) else {
      return nil
    }

    moves = parsed.moves
    startingIndex = .minimum
    positions = parsed.positions
    tags = parsed.tags
  }

  // MARK: - Moves

  /// Perform the provided move in the game.
  ///
  /// - parameter move: The move to perform.
  /// - parameter index: The current move index to make the move from.
  /// If this parameter is `nil` or omitted, the move is made from the
  /// last move in the main variation branch.
  /// - returns: The move index of the resulting position. If the
  /// move couldn't be made, the provided `index` is returned directly.
  ///
  /// This method does not make any move legality assumptions,
  /// it will attempt to make the move defined by `move` by moving
  /// pieces at the provided starting/ending squares and making any
  /// necessary captures, promotions, etc. It is the responsibility
  /// of the caller to ensure the move is legal, see the ``Board`` struct.
  ///
  /// If `move` is the same as the upcoming move in the
  /// current variation of `index`, the move is not made, otherwise
  /// another variation with the same first move as the existing one
  /// would be created.
  @discardableResult
  public mutating func make(
    move: Move,
    from index: MoveTree.Index
  ) -> MoveTree.Index {
    if let existingMoveIndex = moves.nextIndex(containing: move, for: index) {
      // if attempted move already exists next in the variation,
      // skip making it and return the corresponding index
      return existingMoveIndex
    }

    let newIndex = moves.add(move: move, toParentIndex: index)

    guard let currentPosition = positions[index] else {
      return index
    }

    var newPosition = currentPosition

    switch move.result {
    case .move:
      newPosition.move(pieceAt: move.start, to: move.end)
      if move.piece.kind == .pawn { newPosition.resetHalfmoveClock() }
    case let .capture(capturedPiece):
      newPosition.remove(capturedPiece)
      newPosition.move(pieceAt: move.start, to: move.end)
      newPosition.resetHalfmoveClock()
    case let .castle(castling):
      newPosition.castle(castling)
    }

    if let promotedPiece = move.promotedPiece {
      newPosition.promote(pieceAt: move.end, to: promotedPiece.kind)
    }

    positions[newIndex] = newPosition
    return newIndex
  }

  /// Perform the provided move in the game.
  ///
  /// - parameter moveString: The SAN string of the move to perform.
  /// - parameter index: The current move index to make the move from.
  /// If this parameter is `nil` or omitted, the move is made from the
  /// last move in the main variation branch.
  /// - returns: The move index of the resulting position. If the
  /// move couldn't be made, the provided `index` is returned directly.
  ///
  /// This method does not make any move legality assumptions,
  /// it will attempt to make the move defined by `moveString` by moving
  /// pieces at the provided starting/ending squares and making any
  /// necessary captures, promotions, etc. It is the responsibility
  /// of the caller to ensure the move is legal, see the ``Board`` struct.
  @discardableResult
  public mutating func make(
    move moveString: String,
    from index: MoveTree.Index
  ) -> MoveTree.Index {
    guard let position = positions[index],
      let move = SANParser.parse(move: moveString, in: position)
    else {
      return index
    }

    return make(move: move, from: index)
  }

  /// Perform the provided moves in the game.
  ///
  /// - parameter moveStrings: An array of SAN strings of the moves to perform.
  /// - parameter index: The current move index to make the moves from.
  /// If this parameter is `nil` or omitted, the move is made from the
  /// last move in the main variation branch.
  /// - returns: The move index of the resulting position. If the
  /// moves couldn't be made, the provided `index` is returned directly.
  ///
  /// This method does not make any move legality assumptions,
  /// it will attempt to make the moves defined by `moveStrings` by moving
  /// pieces at the provided starting/ending squares and making any
  /// necessary captures, promotions, etc. It is the responsibility
  /// of the caller to ensure the moves are legal, see the ``Board`` struct.
  @discardableResult
  public mutating func make(
    moves moveStrings: [String],
    from index: MoveTree.Index
  ) -> MoveTree.Index {
    var index = index

    for moveString in moveStrings {
      index = make(move: moveString, from: index)
    }

    return index
  }
    

  /// Promotes the piece the a given move to the selected piece.
  ///
  /// - parameter move: The move that promotes the piece.
  /// - parameter kind: The kind of piece we would like to promote to.
  /// - parameter index: The current move index to make the moves from.
  /// If this parameter is `nil` or omitted, the move is made from the
  /// last move in the main variation branch.
  /// - returns: The updated move or nil if the update was unsuccessful
  ///
  /// This method does not make any move legality assumptions,
  /// it will attempt to make the moves defined by `moveStrings` by moving
  /// pieces at the provided starting/ending squares and making any
  /// necessary captures, promotions, etc. It is the responsibility
  /// of the caller to ensure the moves are legal, see the ``Board`` struct.
  @discardableResult
  public mutating func completePromotion(
    of move: Move,
    to kind: Piece.Kind,
    at index: MoveTree.Index? = nil
  ) -> Move? {
    let index = index ?? moves.endIndex
    let promotedPiece = Piece(kind, color: move.piece.color, square: move.end)
    
    guard var position = positions[index] else {
            return nil
    }
        
    var updatedMove = move
    updatedMove.promotedPiece = promotedPiece

    position.promote(pieceAt: move.end, to: kind)
        
    positions[moves.endIndex] = position
    return moves.promotePiece(promotedPiece, at: index)
  }

  /// Annotates the move at the provided `index`.
  ///
  /// - parameter index: The index of the move within the ``MoveTree``.
  /// - parameter assessment: The move assessment annotation.
  /// - parameter comment: The move comment annotation.
  ///
  public mutating func annotate(
    moveAt index: MoveTree.Index,
    assessment: Move.Assessment = .null,
    comment: String = ""
  ) {
    moves.annotate(moveAt: index, assessment: assessment, comment: comment)
  }

  /// The PGN represenation of the game.
  public var pgn: String {
    PGNParser.convert(game: self)
  }

}

// MARK: - Tags

extension Game {

  /// Denotes a PGN tag pair.
  @propertyWrapper
  public struct Tag: Hashable, Sendable {

    /// The name of the tag pair.
    ///
    /// Used as the key in a PGN tag pair.
    public var name: String

    /// The value of the tag pair.
    ///
    /// Appears at the top of the PGN after the
    /// corresponding ``name``, within brackets.
    public var wrappedValue: String = ""

    /// The projected value of this ``Tag`` object.
    public var projectedValue: Tag { self }

    /// The PGN representation of this tag.
    ///
    /// Formatted as `[Name "Value"]`.
    public var pgn: String {
      wrappedValue.isEmpty ? "" : "[\(name) \"\(wrappedValue)\"]"
    }

  }

  /// Contains the PGN tag pairs for a game.
  public struct Tags: Hashable, Sendable {

    /// Whether or not all the standard mandatory tags for
    /// PGN archival are set.
    ///
    /// These include `event`, `site`, `date`, `round`,
    /// `white`, `black`, and `result` (known as the "Seven Tag Roster").
    public var isValid: Bool {
      [event, site, date, round, white, black, result]
        .allSatisfy { !$0.isEmpty }
    }

    /// Name of the tournament or match event.
    ///
    /// Example: `"F/S Return Match"`
    @Tag(name: "Event")
    public var event: String

    /// Location of the event.
    ///
    /// Example: `"Belgrade, Serbia JUG"`
    ///
    /// The format for this value is "City, Region COUNTRY",
    /// where "COUNTRY" is the three-letter International Olympic Committee
    /// code for the country.
    ///
    /// Although not part of the specification, some online chess platforms
    /// will include a URL or website as the site value.
    @Tag(name: "Site")
    public var site: String

    /// Starting date of the game, in YYYY.MM.DD format.
    ///
    /// Example: `"1992.11.04"`
    ///
    /// `"??"` is used for unknown values.
    @Tag(name: "Date")
    public var date: String

    /// Playing round ordinal of the game within the event.
    ///
    /// Example `"29"`
    @Tag(name: "Round")
    public var round: String

    /// Player of the white pieces, in "Lastname, Firstname" format.
    ///
    /// Example: `"Fischer, Robert J."`
    @Tag(name: "White")
    public var white: String

    /// Player of the black pieces, in "Lastname, Firstname" format.
    ///
    /// Example: `"Spassky, Boris V."`
    @Tag(name: "Black")
    public var black: String

    /// Result of the game.
    ///
    /// Example: `"1/2-1/2"`
    ///
    /// It is recorded as White score, dash, then Black score, or `*` (other, e.g., the game is ongoing).
    @Tag(name: "Result")
    public var result: String

    /// The person providing notes to the game. (optional)
    @Tag(name: "Annotator")
    public var annotator: String

    /// String value denoting the total number of half-moves played. (optional)
    @Tag(name: "PlyCount")
    public var plyCount: String

    /// e.g. 40/7200:3600 (moves per seconds: sudden death seconds) (optional)
    @Tag(name: "TimeControl")
    public var timeControl: String

    /// Time the game started, in HH:MM:SS format, in local clock time. (optional)
    @Tag(name: "Time")
    public var time: String

    /// Gives more details about the termination of the game. It may be abandoned, adjudication (result determined by third-party adjudication), death, emergency, normal, rules infraction, time forfeit, or unterminated. (optional)
    @Tag(name: "Termination")
    public var termination: String

    /// The mode of play used for the game. (optional)
    ///
    /// `"OTB"` (over-the-board) or `"ICS"` (Internet Chess Server)
    @Tag(name: "Mode")
    public var mode: String

    /// The initial position of the chessboard, in Forsyth–Edwards Notation. (optional)
    ///
    /// This is used to record partial games (starting at some initial position). It is also necessary for chess variants such as Chess960, where the initial position is not always the same as traditional chess.
    ///
    /// If a FEN tag is used, a separate tag pair SetUp must also appear and have its value set to 1.
    @Tag(name: "FEN")
    public var fen: String

    @Tag(name: "SetUp")
    public var setUp: String

    /// Extra custom tags.
    ///
    /// The key will be used as the tag name in the PGN.
    public var other: [String: String] = [:]

    /// Initializes a `Game.Tags` object with the provided
    /// values.
    ///
    /// For initialization purposes, all values are optional,
    /// and any omitted values will be set to empty strings.
    public init(
      event: String = "",
      site: String = "",
      date: String = "",
      round: String = "",
      white: String = "",
      black: String = "",
      result: String = "",
      annotator: String = "",
      plyCount: String = "",
      timeControl: String = "",
      time: String = "",
      termination: String = "",
      mode: String = "",
      fen: String = "",
      setUp: String = "",
      other: [String: String] = [:]
    ) {
      self.event = event
      self.site = site
      self.date = date
      self.round = round
      self.white = white
      self.black = black
      self.result = result
      self.annotator = annotator
      self.plyCount = plyCount
      self.timeControl = timeControl
      self.time = time
      self.termination = termination
      self.mode = mode
      self.fen = fen
      self.setUp = setUp
      self.other = other
    }
  }

}
