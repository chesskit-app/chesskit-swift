//
//  BoardOperators.swift
//  ChessKit
//

typealias BoardOperation = (Square, Int) -> Square

precedencegroup BoardOperatorPrecedence {
    higherThan: BitwiseShiftPrecedence
    associativity: left
}

infix operator ↑: BoardOperatorPrecedence
infix operator ↓: BoardOperatorPrecedence
infix operator ←: BoardOperatorPrecedence
infix operator →: BoardOperatorPrecedence
infix operator ↗: BoardOperatorPrecedence
infix operator ↙: BoardOperatorPrecedence
infix operator ↖: BoardOperatorPrecedence
infix operator ↘: BoardOperatorPrecedence

// MARK: - Convenience

private func increment(rank: Square.Rank, by spaces: Int) -> Square.Rank {
    Square.Rank(rank.value + spaces)
}

private func increment(file: Square.File, by spaces: Int) -> Square.File {
    let currentFileNumber = file.number - 1
    let newFileNumber = currentFileNumber + spaces
    
    guard newFileNumber >= 0, newFileNumber < Square.File.allCases.count else {
        return file
    }
    
    return Square.File.allCases[newFileNumber]
}

// MARK: - Basic Operations

func ↑ (start: Square, spaces: Int) -> Square {
    Square(start.file, increment(rank: start.rank, by: spaces))
}

func ↓ (start: Square, spaces: Int) -> Square {
    Square(start.file, increment(rank: start.rank, by: -spaces))
}

func ← (start: Square, spaces: Int) -> Square {
    Square(increment(file: start.file, by: -spaces), start.rank)
}

func → (start: Square, spaces: Int) -> Square {
    Square(increment(file: start.file, by: spaces), start.rank)
}

func ↗ (start: Square, spaces: Int) -> Square {
    let maxMovement = min(
        Square.File.h.number - start.file.number,
        Square.Rank.range.upperBound - start.rank.value
    )
    
    let movement = min(spaces, maxMovement)
    return start ↑ movement → movement
}

func ↙ (start: Square, spaces: Int) -> Square {
    let maxMovement = min(
        start.file.number - Square.File.a.number,
        start.rank.value - Square.Rank.range.lowerBound
    )
    
    let movement = min(spaces, maxMovement)
    return start ↓ movement ← movement
}

func ↖ (start: Square, spaces: Int) -> Square {
    let maxMovement = min(
        start.file.number - Square.File.a.number,
        Square.Rank.range.upperBound - start.rank.value
    )
    
    let movement = min(spaces, maxMovement)
    return start ↑ movement ← movement
}

func ↘ (start: Square, spaces: Int) -> Square {
    let maxMovement = min(
        Square.File.h.number - start.file.number,
        start.rank.value - Square.Rank.range.lowerBound
    )
    
    let movement = min(spaces, maxMovement)
    return start ↓ movement → movement
}

// MARK: - Knight Operations

func kNNE(start: Square) -> Square? {
    guard start.file.number <= Square.File.g.number && start.rank.value <= 6 else { return nil }
    return start ↗ 1 ↑ 1
}

func kENE(start: Square) -> Square? {
    guard start.file.number <= Square.File.f.number && start.rank.value <= 7 else { return nil }
    return start ↗ 1 → 1
}

func kESE(start: Square) -> Square? {
    guard start.file.number <= Square.File.f.number && start.rank.value >= 2 else { return nil }
    return start ↘ 1 → 1
}

func kSSE(start: Square) -> Square? {
    guard start.file.number <= Square.File.g.number && start.rank.value >= 3 else { return nil }
    return start ↘ 1 ↓ 1
}

func kSSW(start: Square) -> Square? {
    guard start.file.number >= Square.File.b.number && start.rank.value >= 3 else { return nil }
    return start ↙ 1 ↓ 1
}

func kWSW(start: Square) -> Square? {
    guard start.file.number >= Square.File.c.number && start.rank.value >= 2 else { return nil }
    return start ↙ 1 ← 1
}

func kWNW(start: Square) -> Square? {
    guard start.file.number >= Square.File.c.number && start.rank.value <= 7 else { return nil }
    return start ↖ 1 ← 1
}

func kNNW(start: Square) -> Square? {
    guard start.file.number >= Square.File.b.number && start.rank.value <= 6 else { return nil }
    return start ↖ 1 ↑ 1
}
