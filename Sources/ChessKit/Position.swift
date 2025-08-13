//
//  Position.swift
//  ChessKit
//

/// Represents the collection of pieces on the chess board.
public struct Position: Sendable {

  /// The pieces currently existing on the board in this position.
  public var pieces: [Piece] {
    pieceSet.pieces
  }

  /// Bitboard-based piece set used to manage piece positions.
  private(set) var pieceSet: PieceSet

  /// The side that is set to move next.
  public private(set) var sideToMove: Piece.Color

  /// Legal castlings based on position only (does not take into account checks, etc.
  ///
  /// This array only contains castlings that are legal based on whether
  /// or not the king(s) and rook(s) have moved.
  var legalCastlings: LegalCastlings

  /// Contains information about a pawn that can be captured by en passant.
  ///
  /// This property is set whenever a pawn moves by 2 squares.
  var enPassant: EnPassant?

  /// Indicates whether the en passant stored in `enPassant` is valid.
  var enPassantIsPossible: Bool

  /// Keeps track of the number of moves in a game for the current position.
  public private(set) var clock: Clock

  /// The position assessment annotation.
  public var assessment: Assessment

  /// Initialize a position with a given array of pieces and characteristics.
  init(
    pieces: [Piece],
    sideToMove: Piece.Color = .white,
    legalCastlings: LegalCastlings = .init(),
    enPassant: EnPassant? = nil,
    clock: Clock = .init(),
    assessment: Assessment = .null
  ) {
    self.pieceSet = .init(pieces: pieces)
    self.sideToMove = sideToMove
    self.legalCastlings = legalCastlings
    self.enPassant = enPassant
    self.enPassantIsPossible = enPassant != nil
    self.clock = clock
    self.assessment = assessment
  }

  /// Initialize a move with a provided FEN string.
  ///
  /// This initializer fails if the provided FEN string is invalid.
  public init?(fen: String) {
    guard let parsed = FENParser.parse(fen: fen) else {
      return nil
    }

    self = parsed
  }

  /// Toggle the current side to move.
  private mutating func _toggleSideToMove() {
    sideToMove.toggle()
  }

  /// Provides the chess piece located at the given square.
  ///
  /// - parameter square: The square of the board to query for a piece.
  /// - returns: The piece located at `square`, or `nil` if the square is empty.
  ///
  public func piece(at square: Square) -> Piece? {
    pieceSet.get(square)
  }

  /// Moves the given piece to the given square.
  ///
  /// - parameter piece: The piece to move in this position.
  /// - parameter end: The square that `piece` should be moved to.
  /// - returns: The updated piece containing the final square as its location, or `nil` if the given piece was not found in this position.
  ///
  /// - warning: Do not use this function to perform castling moves.
  /// To castle a king and rook, call `castle(_:)`.
  ///
  @discardableResult
  mutating func move(_ piece: Piece, to end: Square, updateClockAndSideToMove: Bool = true) -> Piece? {
    guard pieceSet.get(piece.square) != nil else { return nil }

    legalCastlings.invalidateCastling(for: piece)
    pieceSet.move(piece, to: end)

    if updateClockAndSideToMove {
      clock.halfmoves += 1

      if piece.color == .black {
        clock.fullmoves += 1
      }

      _toggleSideToMove()
    }

    return pieceSet.get(end)
  }

  /// Moves the given piece to the given square.
  ///
  /// - parameter castling: The castling object contain associated king and rook square information.
  /// - returns: The updated king piece containing the final square as its location, or `nil` if the given piece was not found in this position.
  ///
  /// This function assumes castling is valid for the provided `castling`. If the the king move is
  /// valid, it will be performed whether or not there is actually a piece on the `rookStart` square.
  ///
  /// - note: The rook will only be moved if the king move succeeds.
  ///
  @discardableResult
  mutating func castle(_ castling: Castling) -> Piece? {
    let kingMove = move(pieceAt: castling.kingStart, to: castling.kingEnd)

    defer {
      if kingMove != nil {
        move(pieceAt: castling.rookStart, to: castling.rookEnd, updateClockAndSideToMove: false)
      }
    }

    return kingMove
  }

  /// Moves a piece from one square to another.
  ///
  /// - parameter start: The square where the piece is currently located.
  /// - parameter end: The square that `piece` should be moved to.
  /// - returns: The updated piece containing the final square as its location, or `nil` if the given piece was not found in this position.
  ///
  @discardableResult
  mutating func move(pieceAt start: Square, to end: Square, updateClockAndSideToMove: Bool = true) -> Piece? {
    guard let piece = pieceSet.get(start) else {
      return nil
    }

    return move(piece, to: end, updateClockAndSideToMove: updateClockAndSideToMove)
  }

  /// Removes the given piece from the position.
  ///
  /// - parameter piece: The piece to remove from the position.
  ///
  /// If the piece is not currently located in the position, this method has no effect.
  mutating func remove(_ piece: Piece) {
    pieceSet.remove(piece)
  }

  /// Promotes a pawn at the given square to the given piece type.
  ///
  /// - parameter square: The square on which the pawn should be promoted.
  /// - parameter kind: The type of piece to promote to.
  ///
  /// If a piece is not found at the given square, this method has no effect.
  /// This method contains no logic to determine if the piece can be legally
  /// promoted, and such checks should be done before calling this method.
  mutating func promote(pieceAt square: Square, to kind: Piece.Kind) {
    guard let piece = pieceSet.get(square) else { return }
    pieceSet.replace(kind, for: piece)
  }

  /// Resets the halfmove counter in the `Clock`.
  ///
  /// This should be used whenenever a pawn is moved or a capture is made.
  mutating func resetHalfmoveClock() {
    clock.halfmoves = 0
  }

  /// Indicates whether the current position has insufficient material.
  public var hasInsufficientMaterial: Bool {
    let set = pieceSet
    let pawnsRooksQueens = set.pawns | set.rooks | set.queens

    if pawnsRooksQueens == 0 {
      if set.all.nonzeroBitCount <= 3 {
        // 3 pieces in this scenario means two kings and either
        // 1 bishop or 1 knight, i.e. insufficient material
        return true
      } else {
        // check if no knights and all bishops
        // are on the same color square, i.e. insufficient material
        let allBLight = set.bishops & .dark == 0  // all bishops on light squares
        let allBDark = set.bishops & .light == 0  // all bishops on dark squares

        return set.knights == 0 && (allBLight || allBDark)
      }
    } else {
      // not insufficient material if pawns, rooks, or queens
      // are on the board
      return false
    }
  }

  /// The FEN represenation of the position.
  public var fen: String {
    FENParser.convert(position: self)
  }

}

// MARK: - Assessment
extension Position {

  /// Single position assessments.
  ///
  /// The raw String value corresponds to what is displayed
  /// in a PGN string.
  public enum Assessment: String, Sendable {
    case null = ""
    case drawishPosition = "$10"
    case equalChancesQuietPosition = "$11"
    case equalChancesActivePosition = "$12"
    case unclearPosition = "$13"
    case whiteHasSlightAdvantage = "$14"
    case blackHasSlightAdvantage = "$15"
    case whiteHasModerateAdvantage = "$16"
    case blackHasModerateAdvantage = "$17"
    case whiteHasDecisiveAdvantage = "$18"
    case blackHasDecisiveAdvantage = "$19"
    case whiteHasCrushingAdvantage = "$20"
    case blackHasCrushingAdvantage = "$21"
    case whiteInZugzwang = "$22"
    case blackInZugzwang = "$23"
    case whiteHasSlightSpaceAdvantage = "$24"
    case blackHasSlightSpaceAdvantage = "$25"
    case whiteHasModerateSpaceAdvantage = "$26"
    case blackHasModerateSpaceAdvantage = "$27"
    case whiteHasDecisiveSpaceAdvantage = "$28"
    case blackHasDecisiveSpaceAdvantage = "$29"
    case whiteHasSlightTimeAdvantage = "$30"
    case blackHasSlightTimeAdvantage = "$31"
    case whiteHasModerateTimeAdvantage = "$32"
    case blackHasModerateTimeAdvantage = "$33"
    case whiteHasDecisiveTimeAdvantage = "$34"
    case blackHasDecisiveTimeAdvantage = "$35"
    case whiteHasInitiative = "$36"
    case blackHasInitiative = "$37"
    case whiteHasLastingInitiative = "$38"
    case blackHasLastingInitiative = "$39"
    case whiteHasAttack = "$40"
    case blackHasAttack = "$41"
    case whiteInsufficientCompensation = "$42"
    case blackInsufficientCompensation = "$43"
    case whiteSufficientCompensation = "$44"
    case blackSufficientCompensation = "$45"
    case whiteMoreThanAdequateCompensation = "$46"
    case blackMoreThanAdequateCompensation = "$47"
    case whiteHasSlightCenterControlAdvantage = "$48"
    case blackHasSlightCenterControlAdvantage = "$49"
    case whiteHasModerateCenterControlAdvantage = "$50"
    case blackHasModerateCenterControlAdvantage = "$51"
    case whiteHasDecisiveCenterControlAdvantage = "$52"
    case blackHasDecisiveCenterControlAdvantage = "$53"
    case whiteHasSlightKingsideControlAdvantage = "$54"
    case blackHasSlightKingsideControlAdvantage = "$55"
    case whiteHasModerateKingsideControlAdvantage = "$56"
    case blackHasModerateKingsideControlAdvantage = "$57"
    case whiteHasDecisiveKingsideControlAdvantage = "$58"
    case blackHasDecisiveKingsideControlAdvantage = "$59"
    case whiteHasSlightQueensideControlAdvantage = "$60"
    case blackHasSlightQueensideControlAdvantage = "$61"
    case whiteHasModerateQueensideControlAdvantage = "$62"
    case blackHasModerateQueensideControlAdvantage = "$63"
    case whiteHasDecisiveQueensideControlAdvantage = "$64"
    case blackHasDecisiveQueensideControlAdvantage = "$65"
    case whiteVulnerableFirstRank = "$66"
    case blackVulnerableFirstRank = "$67"
    case whiteWellProtectedFirstRank = "$68"
    case blackWellProtectedFirstRank = "$69"
    case whitePoorlyProtectedKing = "$70"
    case blackPoorlyProtectedKing = "$71"
    case whiteWellProtectedKing = "$72"
    case blackWellProtectedKing = "$73"
    case whitePoorlyPlacedKing = "$74"
    case blackPoorlyPlacedKing = "$75"
    case whiteWellPlacedKing = "$76"
    case blackWellPlacedKing = "$77"
    case whiteVeryWeakPawnStructure = "$78"
    case blackVeryWeakPawnStructure = "$79"
    case whiteModeratelyWeakPawnStructure = "$80"
    case blackModeratelyWeakPawnStructure = "$81"
    case whiteModeratelyStrongPawnStructure = "$82"
    case blackModeratelyStrongPawnStructure = "$83"
    case whiteVeryStrongPawnStructure = "$84"
    case blackVeryStrongPawnStructure = "$85"
    case whitePoorKnightPlacement = "$86"
    case blackPoorKnightPlacement = "$87"
    case whiteGoodKnightPlacement = "$88"
    case blackGoodKnightPlacement = "$89"
    case whitePoorBishopPlacement = "$90"
    case blackPoorBishopPlacement = "$91"
    case whiteGoodBishopPlacement = "$92"
    case blackGoodBishopPlacement = "$93"
    case whitePoorRookPlacement = "$94"
    case blackPoorRookPlacement = "$95"
    case whiteGoodRookPlacement = "$96"
    case blackGoodRookPlacement = "$97"
    case whitePoorQueenPlacement = "$98"
    case blackPoorQueenPlacement = "$99"
    case whiteGoodQueenPlacement = "$100"
    case blackGoodQueenPlacement = "$101"
    case whitePoorPieceCoordination = "$102"
    case blackPoorPieceCoordination = "$103"
    case whiteGoodPieceCoordination = "$104"
    case blackGoodPieceCoordination = "$105"
    case whitePlayedOpeningVeryPoorly = "$106"
    case blackPlayedOpeningVeryPoorly = "$107"
    case whitePlayedOpeningPoorly = "$108"
    case blackPlayedOpeningPoorly = "$109"
    case whitePlayedOpeningWell = "$110"
    case blackPlayedOpeningWell = "$111"
    case whitePlayedOpeningVeryWell = "$112"
    case blackPlayedOpeningVeryWell = "$113"
    case whitePlayedMiddlegameVeryPoorly = "$114"
    case blackPlayedMiddlegameVeryPoorly = "$115"
    case whitePlayedMiddlegamePoorly = "$116"
    case blackPlayedMiddlegamePoorly = "$117"
    case whitePlayedMiddlegameWell = "$118"
    case blackPlayedMiddlegameWell = "$119"
    case whitePlayedMiddlegameVeryWell = "$120"
    case blackPlayedMiddlegameVeryWell = "$121"
    case whitePlayedEndingVeryPoorly = "$122"
    case blackPlayedEndingVeryPoorly = "$123"
    case whitePlayedEndingPoorly = "$124"
    case blackPlayedEndingPoorly = "$125"
    case whitePlayedEndingWell = "$126"
    case blackPlayedEndingWell = "$127"
    case whitePlayedEndingVeryWell = "$128"
    case blackPlayedEndingVeryWell = "$129"
    case whiteHasSlightCounterplay = "$130"
    case blackHasSlightCounterplay = "$131"
    case whiteHasModerateCounterplay = "$132"
    case blackHasModerateCounterplay = "$133"
    case whiteHasDecisiveCounterplay = "$134"
    case blackHasDecisiveCounterplay = "$135"
    case whiteModerateTimeControlPressure = "$136"
    case blackModerateTimeControlPressure = "$137"
    case whiteSevereTimeControlPressure = "$138"
    case blackSevereTimeControlPressure = "$139"
  }

}

// MARK: - Sample Positions
extension Position {
  /// A random chess position that can be used for testing.
  public static let test = Position(pieces: [
    Piece(.pawn, color: .black, square: .c3),
    Piece(.bishop, color: .black, square: .f4),
    Piece(.rook, color: .black, square: .a6),
    Piece(.knight, color: .black, square: .e6),
    Piece(.king, color: .black, square: .h8),
    Piece(.pawn, color: .white, square: .b2),
    Piece(.queen, color: .white, square: .d5),
    Piece(.king, color: .white, square: .g3)
  ])

  /// The standard starting chess position.
  public static let standard = Position(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")!
}

// MARK: - CustomStringConvertible
extension Position: CustomStringConvertible {

  public var description: String {
    String(describing: pieceSet)
  }

}

// MARK: - Hashable
extension Position: Hashable {

  public func hash(into hasher: inout Hasher) {
    hasher.combine(pieceSet)
    hasher.combine(sideToMove)
    hasher.combine(legalCastlings)
    hasher.combine(enPassantIsPossible)
  }

}

// MARK: - Deprecated
extension Position {

  /// Toggle the current side to move.
  @available(*, deprecated, message: "This function no longer has any effect. `sideToMove` is toggled automatically as needed.")
  public mutating func toggleSideToMove() {

  }

}
