# ChessKit 0.3.2
Released Saturday, December 2, 2023.

#### Fixes
* Made `file` and `rank` public properties of `Square`.

# ChessKit 0.3.1
Released Friday, November 24, 2023.

#### Improvements
* Added `CaseIterable` conformance to several `Piece` and `Square` enums:
    * `Piece.Color`
    * `Piece.Kind`
    * `Square.Color`

# ChessKit 0.3.0
Released Wednesday, June 21, 2023.

#### New Features
* Add `future(for:)` and `fullVariation(for:)` methods to `MoveTree`.
	* `future(for:)` returns the future moves for a given
index.
	* `fullVariation(for:)` returns the sum of `history(for:)` and `future(for:)`.

#### Improvements
* Simplify `PGNElement` to just contain a single `.move` case.
	* i.e. `.whiteMove` and `blackMove` have been removed and consolidated.

#### Fixes
* Fix behavior of `previousIndex(for:)` and `nextIndex(for:)` in `MoveTree`.
	* Especially when the provided `index` is equal to `.minimum`.

# ChessKit 0.2.0
Released Wednesday, May 31, 2023.

#### New Features
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

#### Removed
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
