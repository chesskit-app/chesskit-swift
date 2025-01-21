//
//  BBBoard.swift
//  ChessKit
//

/// Delegate protocol that allows the implementer to receive
/// events related to changes in position on the board such
/// as pawn promotions and end results.
public protocol BoardDelegate: AnyObject, Sendable {
  func willPromote(with move: Move)
  func didPromote(with move: Move)
  func didCheckKing(ofColor color: Piece.Color)
  func didEnd(with result: Board.EndResult)
}

/// Manages the state of the chess board and validates
/// legal moves and game rules.
public struct Board: Sendable {

  // MARK: - Properties

  /// The delegate for this board object.
  ///
  /// Used to communicate certain events as
  /// the ``position`` changes.
  public weak var delegate: BoardDelegate?

  /// The current position represented on the board.
  public var position: Position

  /// A dictionary containing the occurrence counts for all the positions
  /// that have appeared on this board, keyed by the position's hash.
  ///
  /// This is used to determine draw by repetition.
  private var positionHashCounts: [Int: Int]

  /// Convenience accessor for the pieces in `position`.
  private var set: PieceSet {
    position.pieceSet
  }

  // MARK: - Initializer

  /// Initializes a board with the given `position`.
  ///
  /// - parameter position: The starting position of the board.
  /// The default is `Position.standard` which is the starting position
  /// for a standard chess game.
  ///
  public init(position: Position = .standard) {
    Attacks.create()
    self.position = position
    self.positionHashCounts = [:]
  }

  // MARK: - Public

  /// Moves the piece at a given square to a new square.
  ///
  /// - parameter start: The starting square of the piece.
  /// - parameter end: The ending square of the piece.
  ///
  /// - returns: The ``Move`` object representing the move.
  ///
  /// If `start` doesn't contain a piece or `end` is not a valid legal move
  /// for the piece at `start`, `nil` is returned.
  ///
  /// The return value can be ignored if the intention is only to perform
  /// the move but not capture the details in any way. If the move is
  /// not legal, this method returns without performing any actions.
  ///
  /// This method also handles all the side effects of a given move.
  ///
  /// For example:
  /// - Moving the king in a castling move will also move the
  /// corresponding rook.
  /// - Moving to capture a piece removes the captured piece from the board.
  @discardableResult
  public mutating func move(pieceAt start: Square, to end: Square) -> Move? {
    guard canMove(pieceAt: start, to: end), let piece = set.get(start) else {
      return nil
    }

    // en passant

    if piece.kind == .pawn,
      let enPassant = position.enPassant,
      enPassant.pawn.color == piece.color.opposite,
      end == enPassant.captureSquare
    {
      position.remove(enPassant.pawn)
      position.move(piece, to: end)
      return process(move: Move(result: .capture(enPassant.pawn), piece: piece, start: start, end: end))
    } else {
      position.enPassant = nil  // prevent en passant on next turn
      position.enPassantIsPossible = false
    }

    // castling

    if piece.kind == .king {
      let castles = Castling.Side.allCases
        .map { Castling(side: $0, color: piece.color) }
        .compactMap {
          (castling: Castling) -> Move? in

          if canCastle(piece.color, castling: castling, set: set) && end == castling.kingEnd {
            position.castle(castling)
            return Move(result: .castle(castling), piece: piece, start: start, end: end)
          } else {
            return nil
          }
        }

      if let castle = castles.first {
        return process(move: castle)
      }
    }

    // captures & moves

    if let endPiece = position.piece(at: end), endPiece.color == piece.color.opposite {
      let move = disambiguate(
        move: Move(
          result: .capture(endPiece),
          piece: piece,
          start: start,
          end: end
        ),
        in: set
      )

      position.remove(endPiece)
      position.move(piece, to: end)
      position.resetHalfmoveClock()

      return process(move: move)
    } else {
      let previousSet = set

      guard let updatedPiece = position.move(piece, to: end) else {
        return nil
      }

      let move = disambiguate(
        move: Move(
          result: .move,
          piece: updatedPiece,
          start: start,
          end: end
        ),
        in: previousSet
      )

      if updatedPiece.kind == .pawn {
        position.resetHalfmoveClock()

        if abs(start.rank.value - end.rank.value) == 2 {
          position.enPassant = EnPassant(pawn: updatedPiece)
          position.enPassantIsPossible = enPassantIsValid
        }
      }

      return process(move: move)
    }
  }

  /// Checks if a piece at a given square can be moved to a new square.
  ///
  /// - parameter square: The square currently containing the piece.
  /// - parameter newSquare: The new square for the piece.
  ///
  /// - returns: Whether or not the move is valid.
  ///
  public func canMove(pieceAt square: Square, to newSquare: Square) -> Bool {
    guard let piece = set.get(square) else { return false }
    return legalMoves(for: piece, in: set) & newSquare.bb != 0
  }

  /// Returns the possible legal moves for a piece at a given square.
  ///
  /// - parameter square: The square containing the piece to check.
  ///
  /// - returns: An array of squares containing legal moves or an empty
  /// array if there are no legal moves or if there is no piece at `square`.
  ///
  public func legalMoves(forPieceAt square: Square) -> [Square] {
    guard let piece = set.get(square) else { return [] }
    return legalMoves(for: piece, in: set).squares
  }

  /// Completes a pawn promotion move.
  ///
  /// - parameter move: The move that triggered the promotion.
  /// - parameter kind: The piece kind to promote a pawn to.
  ///
  /// - returns: The final move containing the promoted piece.
  ///
  /// Call this when a pawn reaches the opposite side of the board
  /// and a piece to promote to is selected to complete the promotion
  /// move.
  @discardableResult
  public mutating func completePromotion(of move: Move, to kind: Piece.Kind) -> Move {
    let promotedPiece = Piece(kind, color: move.piece.color, square: move.end)

    var updatedMove = move
    updatedMove.promotedPiece = promotedPiece

    position.promote(pieceAt: move.end, to: kind)
    return process(move: updatedMove)
  }

  // MARK: - Move Processing

  /// Determines end game state and
  /// handles pawn promotion for provided `move`.
  private mutating func process(move: Move) -> Move {
    var processedMove = move

    // checks & mate
    let checkState = self.checkState(for: move.piece.color)
    processedMove.checkState = checkState

    // draw by repetition
    positionHashCounts[position.hashValue, default: 0] += 1

    // board state notification
    if checkState == .checkmate {
      delegate?.didEnd(with: .win(move.piece.color))
    } else if checkState == .stalemate {
      delegate?.didEnd(with: .draw(.stalemate))
    } else if position.clock.halfmoves >= Clock.halfMoveMaximum {
      delegate?.didEnd(with: .draw(.fiftyMoves))
    } else if position.hasInsufficientMaterial {
      delegate?.didEnd(with: .draw(.insufficientMaterial))
    } else if positionHashCounts[position.hashValue] == 3 {
      delegate?.didEnd(with: .draw(.repetition))
    } else if checkState == .check {
      delegate?.didCheckKing(ofColor: processedMove.piece.color.opposite)
    }

    // pawn promotion
    if move.piece.kind == .pawn {
      if (move.end.rank == 8 && move.piece.color == .white) || (move.end.rank == 1 && move.piece.color == .black) {
          if move.promotedPiece == nil {
              //Notify the user that the move resulted in
              //a promotion and wait for promotion selection.
              delegate?.willPromote(with: move)
          } else {
              //Notify the user that a piece was promoted.
              delegate?.didPromote(with: move)
          }
      }
    }

    return processedMove
  }

  /// Determines the current check state for the provided `color`.
  private func checkState(for color: Piece.Color) -> Move.CheckState {
    var checkState: Move.CheckState = .none

    let legalMoves = set.get(color.opposite)
      .squares
      .flatMap(legalMoves(forPieceAt:))

    if isKingInCheck(color.opposite, set: set) {
      checkState = legalMoves.isEmpty ? .checkmate : .check
    } else {
      checkState = legalMoves.isEmpty ? .stalemate : .none
    }

    return checkState
  }

  /// Disambiguates any moves in `set` as they relate to `move`.
  ///
  /// For example, if two identical pieces can legally move
  /// to a given square, this method determines whether to
  /// disambiguate them by starting file, rank, or square.
  private func disambiguate(move: Move, in set: PieceSet) -> Move {
    let movePiece = move.piece

    let disambiguationCandidates =
      set.get(movePiece.color)  // same color as move piece
      & set.get(movePiece.kind)  // same kind as move piece
      & ~(set.pawns | set.kings)  // not pawns & kings
      & ~move.start.bb  // not piece making move

    let ambiguousPieces = disambiguationCandidates.squares.filter { square in
      guard let piece = set.get(square) else { return false }
      return legalMoves(for: piece, in: set) & move.end.bb != 0
    }

    if ambiguousPieces.isEmpty {
      return move
    } else {
      var newMove = move

      if ambiguousPieces.allSatisfy({ $0.file != move.start.file }) {
        newMove.disambiguation = .byFile(move.start.file)
      } else if ambiguousPieces.allSatisfy({ $0.rank != move.start.rank }) {
        newMove.disambiguation = .byRank(move.start.rank)
      } else {
        newMove.disambiguation = .bySquare(move.start)
      }

      return newMove
    }
  }

  // MARK: - Move Validation

  /// Determines the legal moves for the given `piece` in `set`.
  private func legalMoves(for piece: Piece, in set: PieceSet) -> Bitboard {
    let attacks =
      switch piece.kind {
      case .king:
        kingMoves(piece.color, from: piece.square.bb, set: set)
      case .queen:
        queenAttacks(from: piece.square, occupancy: set.all)
      case .rook:
        rookAttacks(from: piece.square, occupancy: set.all)
      case .bishop:
        bishopAttacks(from: piece.square, occupancy: set.all)
      case .knight:
        knightAttacks[piece.square.bb, default: 0]
      case .pawn:
        pawnAttacks(piece.color, from: piece.square.bb, set: set)
      }

    let us = set.get(piece.color)
    let pseudoLegalMoves = attacks & ~us

    let legalMoves = pseudoLegalMoves.squares.filter {
      validate(moveFor: piece, to: $0)
    }

    return legalMoves.bb
  }

  /// Determines if a pseudo-legal move for a piece to a given square
  /// is valid.
  ///
  /// - parameter piece: The piece to move.
  /// - parameter square: The square to move the piece to.
  ///
  /// - returns: Whether the move is valid.
  ///
  private func validate(moveFor piece: Piece, to square: Square) -> Bool {
    // attempt move in test set
    var testSet = set
    testSet.remove(piece)

    var movedPiece = piece
    movedPiece.square = square
    testSet.add(movedPiece)

    if let enPassant = position.enPassant {
      if enPassant.couldBeCaptured(by: piece) && enPassant.captureSquare == square {
        testSet.remove(enPassant.pawn)
      }
    }

    return !isKingInCheck(piece.color, set: testSet)
  }

  /// Whether the `enPassant` stored in `position` is valid.
  private var enPassantIsValid: Bool {
    if let ep = position.enPassant {
      for square in [ep.pawn.square.left, ep.pawn.square.right] {
        if let piece = position.piece(at: square),
          ep.couldBeCaptured(by: piece),
          validate(moveFor: piece, to: ep.captureSquare)
        {
          return true
        }
      }
    }

    return false
  }

  /// Determines the positions of pieces that attack a given square.
  ///
  /// - parameter sq: A bitboard corresponding to the square of interest.
  /// - parameter set: The piece set for which to calculate attackers.
  ///
  /// - returns: A bitboard with the locations of the pieces in `set`
  /// that attack `sq`.
  ///
  private func attackers(
    to sq: Bitboard,
    set: PieceSet
  ) -> Bitboard {
    guard let square = Square(sq) else { return 0 }

    return kingAttacks[sq, default: 0] & set.kings
      | rookAttacks(from: square, occupancy: set.all) & set.lines
      | bishopAttacks(from: square, occupancy: set.all) & set.diagonals
      | knightAttacks[sq, default: 0] & set.knights
      | pawnCaptures(.white, from: sq) & set.p
      | pawnCaptures(.black, from: sq) & set.P
  }

  /// Determines if the king of the given piece color is in check.
  ///
  /// - parameter color: The color of the king.
  /// - parameter set: The set of pieces on the board.
  ///
  /// - returns: Whether or not the king with `color` is in check.
  ///
  private func isKingInCheck(_ color: Piece.Color, set: PieceSet) -> Bool {
    let us = set.get(color)
    let attacks = attackers(to: set.kings & us, set: set)

    return attacks & ~us != 0
  }

  // MARK: - Piece Attacks

  /// Non-capturing pawn moves.
  ///
  /// - parameter color: The color of the pawn.
  /// - parameter sq: A bitboard representing the square the pawn is currently on.
  /// - parameter set: The set of pieces active on the board.
  /// - returns: A bitboard of the possible non-capturing pawn moves.
  ///
  /// For the purposes of ``Board``, en-passant is considered a non-capturing move.
  private func pawnMoves(
    _ color: Piece.Color,
    from sq: Bitboard,
    set: PieceSet
  ) -> Bitboard {
    let movement: (Int) -> Bitboard
    let isOnStartingRank: Bool

    switch color {
    case .white:
      movement = sq.north
      isOnStartingRank = sq & .rank1.north() != 0
    case .black:
      movement = sq.south
      isOnStartingRank = sq & .rank8.south() != 0
    }

    // single pawn push
    let singleMove = movement(1)

    // double pawn push for starting move
    let extraMove = isOnStartingRank ? movement(2) : 0

    // en passant move
    var enPassantMove = Bitboard(0)

    if let enPassant = position.enPassant,
      let square = Square(sq),
      let piece = set.get(square),
      enPassant.couldBeCaptured(by: piece)
    {
      enPassantMove = enPassant.captureSquare.bb
    }

    return (singleMove | extraMove | enPassantMove) & ~set.all
  }

  /// Capturing pawn moves.
  ///
  /// - parameter color: The color of the pawn.
  /// - parameter sq: A bitboard representing the square the pawn is currently on.
  /// - parameter set: The set of pieces active on the board.
  ///
  /// - returns: A bitboard of the possible capturing pawn moves.
  ///
  /// For the purposes of ``Board``, en-passant is not considered a capturing move.
  private func pawnCaptures(
    _ color: Piece.Color,
    from sq: Bitboard
  ) -> Bitboard {
    switch color {
    case .white: (sq.northWest() | sq.northEast())
    case .black: (sq.southWest() | sq.southEast())
    }
  }

  /// The complete set of pawn moves, including capturing and non-capturing moves.
  ///
  /// - parameter color: The color of the pawn.
  /// - parameter sq: A bitboard representing the square the pawn is currently on.
  /// - parameter set: The set of pieces active on the board.
  ///
  /// - returns: A bitboard of the possible pawn moves.
  ///
  private func pawnAttacks(
    _ color: Piece.Color,
    from sq: Bitboard,
    set: PieceSet
  ) -> Bitboard {
    pawnMoves(color, from: sq, set: set) | pawnCaptures(color, from: sq) & set.get(color.opposite)
  }

  /// Cached knight attack bitboards by square.
  private var knightAttacks: [Bitboard: Bitboard] { Attacks.knights }

  /// Returns cached bishop attack bitboards by square and occupancy.
  private func bishopAttacks(
    from square: Square,
    occupancy: Bitboard
  ) -> Bitboard {
    Attacks.bishops.attacks(from: square, for: occupancy)
  }

  /// Returns cached rook attack bitboards by square and occupancy.
  private func rookAttacks(
    from square: Square,
    occupancy: Bitboard
  ) -> Bitboard {
    Attacks.rooks.attacks(from: square, for: occupancy)
  }

  /// Returns cached queen attack bitboards by square and occupancy.
  private func queenAttacks(
    from square: Square,
    occupancy: Bitboard
  ) -> Bitboard {
    rookAttacks(from: square, occupancy: occupancy)
      | bishopAttacks(from: square, occupancy: occupancy)
  }

  /// Cached king attack bitboards by square.
  private var kingAttacks: [Bitboard: Bitboard] { Attacks.kings }

  /// King attacks from a given square plus castling moves.
  private func kingMoves(
    _ color: Piece.Color,
    from sq: Bitboard,
    set: PieceSet
  ) -> Bitboard {
    var castleMoves = [Square]()

    let kingSide = Castling(side: .king, color: color)
    if canCastle(color, castling: kingSide, set: set) {
      castleMoves.append(kingSide.kingEnd)
    }

    let queenSide = Castling(side: .queen, color: color)
    if canCastle(color, castling: queenSide, set: set) {
      castleMoves.append(queenSide.kingEnd)
    }

    return kingAttacks[sq, default: 0] + castleMoves.bb
  }

  /// Determines whether the king of the provided `color` can
  /// castle according to `castling` given `set`.
  private func canCastle(_ color: Piece.Color, castling: Castling, set: PieceSet) -> Bool {
    let us = set.get(color)

    let validKing = us & set.get(.king) & castling.kingStart.bb
    let validRook = us & set.get(.rook) & castling.rookStart.bb

    let pathClear = castling.path.allSatisfy {
      set.get($0) == nil
    }

    let notCastlingThroughCheck = castling.squares.allSatisfy {
      attackers(to: $0.bb, set: set) & ~us == 0
    }

    let notInCheck = !isKingInCheck(color, set: set)

    return position.legalCastlings.contains(castling)
      && validKing != 0
      && validRook != 0
      && pathClear
      && notCastlingThroughCheck
      && notInCheck
  }

}

// MARK: - End Result

extension Board {
  /// Represents an end result of a standard chess game.
  public enum EndResult: Hashable, Sendable {
    /// The board represents a win for the given color.
    case win(Piece.Color)
    /// The board represents a draw with a given reason.
    case draw(DrawType)

    /// The type of draw represented on the board.
    public enum DrawType: String, Sendable {
      case agreement
      case fiftyMoves
      case insufficientMaterial
      case repetition
      case stalemate
    }
  }
}

extension Board: CustomStringConvertible {

  public var description: String {
    String(describing: position)
  }

}
