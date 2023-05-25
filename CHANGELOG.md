# [Unreleased]

#### Added
* `MoveTree` and `MoveTree.Index` objects to track move turns and variations.
    * `Game.moves` is now a `MoveTree` object instead of `[Int: MovePair]`
    * `MoveTree.Index` includes piece color and variation so it can be used to directly identify any single move within a game
    * Use the properties and functions of `MoveTree` to retrieve moves within the tree as needed

* `make(move:index:)` and `make(moves:index:)` with ability to make moves on `Game` with SAN strings for convenience
    * For example: `game.make(moves: ["e4", "e5"])`

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
