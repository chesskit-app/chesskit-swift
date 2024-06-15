# ChessKit 0.9.0
Released Saturday, June 15, 2024.

### Improvements
* `MoveTree` now conforms to `BidirectionalCollection`, allowing for more standard collection-based semantics in Swift.
  * Should not affect any existing functionality or API usage.
  * Several methods on `MoveTree` have been deprecated in favor of their `Collection` counterparts:
    * `previousIndex(for:)` → `index(before:)` / `hasIndex(before:)`
    * `nextIndex(for:)` → `index(after:)` / `hasIndex(after:)`
    * `move(at:)` → `subscript(_:)` (e.g. `tree[index]`)
* `MoveTree.annotate()` now optionally returns the `Move` object after annotation.
* `MoveTree.path()` now returns tuple with named parameters (`direction` and `index`).

### Bug Fixes
* Removed `CustomDebugStringConvertible` conformance from `Bitboard` to avoid affecting all `UInt64` debug prints.
  * To print the string representation of `Bitboard` use `Bitboard.chessString()`.

# ChessKit 0.8.0
Released Friday, June 7, 2024.

### Improvements
* Add support for draw by insufficient material (by [@joee-ca](https://github.com/joee-ca)).
  * Once this condition is reached `.draw(.insufficientMaterial)` will be published via the `BoardDelegate.didEnd(with:)` method.
* Add unicode variant selector when printing black pawn icon to avoid displaying emoji (by [@joee-ca](https://github.com/joee-ca)).

### Bug Fixes
* Fix issue where king could castle through other pieces (by [@TigranSaakyan](https://github.com/TigranSaakyan)).

# ChessKit 0.7.1
Released Monday, May 6, 2024.

* Fix `MoveTree.previousIndex(for:)` when provided index is one after `minimumIndex`.

# ChessKit 0.7.0
Released Monday, April 29, 2024.

### Improvements
* Add `startingIndex` and `startingPosition` to `Game`.
  * `startingIndex` takes into account the `sideToMove` of `startingPosition`.

### Bug Fixes
* Fix rare en passant issue that could allow the king to be left in check, see [Issue #18](https://github.com/chesskit-app/chesskit-swift/issues/18).

# ChessKit 0.6.0
Released Friday, April 19, 2024.

### Improvements
* Enable `chesskit-swift` to run on oldest platform possible without code changes.
  * Now works on iOS 13+, macOS 10.15+, tvOS 13+, watchOS 6+.
* Annotations on moves in the `MoveTree` can now also be updated via `Game.annotate(moveAt:assessment:comment:)`.

### Bug Fixes
* Fix `MoveTree` not properly publishing changes via `Game`.
* Fix `Board.EndResult.repetition` spelling.
  * This isn't made available yet but will be implemented in an upcoming release.

# ChessKit 0.5.0
Released Sunday, April 14, 2024.

### Improvements
* PGN parsing now supports tag pairs (for example `[Event "Name"]`) located at the top of the PGN format, see [Issue #8](https://github.com/chesskit-app/chesskit-swift/issues/8).

### Bug Fixes
* Fix issue where king is allowed to castle in check, see [Issue #11](https://github.com/chesskit-app/chesskit-swift/issues/11).

### Breaking Changes
* Remove `color` parameter from `Move.init(san:color:position:)` initializer.
  * It was not being used, can be removed from any initializer call where it was included.
  * The new initializer is simply `Move.init(san:position:)`.

# ChessKit 0.4.0
Released Saturday, April 13, 2024.

### Improvements
* `Board` move calculation and validation performance has greatly increased.
  * Performance has improved by over 250x when simulating a full game using `Board`.
  * Underlying board representation has been replaced with much faster bitboard structures and algorithms.
* Add `CustomStringConvertible` conformance to `Board` and `Position` to allow for printing chess board representations, useful for debugging.
* Add `ChessKitConfiguration` with static configuration properties for the package.
  * Currently the only option is `printMode` to determine how pieces should be represented when printing `Board` and `Position` objects (see previous item).

### Breaking Changes
* `EnPassant` has been made an `internal struct`. It is used interally by `Position` and `Board`.

### Deprecations
* `Position.toggleSideToMove()` is now private and handled automatically when calling `move()`. The public-facing `toggleSideToMove()` has been deprecated.

# ChessKit 0.3.2
Released Saturday, December 2, 2023.

### Fixes
* Made `file` and `rank` public properties of `Square`.

# ChessKit 0.3.1
Released Friday, November 24, 2023.

### Improvements
* Add `CaseIterable` conformance to several `Piece` and `Square` enums:
    * `Piece.Color`
    * `Piece.Kind`
    * `Square.Color`

# ChessKit 0.3.0
Released Wednesday, June 21, 2023.

### New Features
* Add `future(for:)` and `fullVariation(for:)` methods to `MoveTree`.
	* `future(for:)` returns the future moves for a given
index.
	* `fullVariation(for:)` returns the sum of `history(for:)` and `future(for:)`.

### Improvements
* Simplify `PGNElement` to just contain a single `.move` case.
	* i.e. `.whiteMove` and `blackMove` have been removed and consolidated.

### Fixes
* Fix behavior of `previousIndex(for:)` and `nextIndex(for:)` in `MoveTree`.
	* Especially when the provided `index` is equal to `.minimum`.

# ChessKit 0.2.0
Released Wednesday, May 31, 2023.

### New Features
* `MoveTree` and `MoveTree.Index` objects to track move turns and variations.
    * `Game.moves` is now a `MoveTree` object instead of `[Int: MovePair]`
    * `MoveTree.Index` includes piece color and variation so it can be used to directly identify any single move within a game
    * Use the properties and functions of `MoveTree` to retrieve moves within the tree as needed

* `make(move:index:)` and `make(moves:index:)` with ability to make moves on `Game` with SAN strings for convenience
    * For example: `game.make(moves: ["e4", "e5"])`

* `PGNParser.convert(game:)` now returns the PGN string for a given game, including variations.
    * Note: `PGNParser.parse(pgn:)` still does not work with variations, this is coming in a future update.

* `Game.positions` is now public
    * Contains a dictionary of all positions in the game by `MoveTree.Index`, including variations

### Removed
* `Game.annotateMove`
    * Modify `Move.assessment` and `Move.comment` directly instead
* `MovePair`
    * Use `Move` in conjuction with `MoveTree.Index` to track move indicies
* `color` parameter from `SANParser.parse()`
    * The color is now obtained from the `sideToMove` in the provided `position`

# ChessKit 0.1.2
Released Thursday, May 11, 2023.

* Add documentation for all public members
* Add default starting position for `Game` initializer
* Add ability to annotate moves via `Game`

# ChessKit 0.1.1
Released Wednesday, April 12, 2023.

* Downgrade required Swift version to 5.7
	* Allows use with Xcode 14.2 on GitHub Actions

# ChessKit 0.1.0
Released Tuesday, April 11, 2023.

* Initial release
