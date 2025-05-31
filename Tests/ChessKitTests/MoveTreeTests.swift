//
//  MoveTreeTests.swift
//  ChessKitTests
//

@testable import ChessKit
import XCTest

final class MoveTreeTests: XCTestCase {

  func testEmptyCollection() {
    let minimum = MoveTree.Index.getMinimum()
    let moveTree = MoveTree()
      
    XCTAssertTrue(moveTree.isEmpty)
    XCTAssertEqual(moveTree.startIndex, minimum)
    XCTAssertEqual(moveTree.endIndex, minimum)

    XCTAssertFalse(moveTree.hasIndex(before: minimum))
    XCTAssertFalse(moveTree.hasIndex(after: minimum))
  }

  func testSubscript() {
    var moveTree = MoveTree()
    let minimum = MoveTree.Index.getMinimum()
    XCTAssertNil(moveTree[minimum])

    let e4 = Move(san: "e4", position: .standard)
    moveTree[minimum.next] = e4
    XCTAssertEqual(moveTree[minimum.next], e4)
  }

  func testNodeHashValueForWhite() {
    var moveTree = MoveTree()
    let minimum = MoveTree.Index.getMinimum()

    let e4 = Move(san: "e4", position: .standard)
    moveTree[minimum.next] = e4
    XCTAssertNotNil(moveTree.dictionary[minimum.next]?.hashValue)
  }

  func testNodeHashValueForBlack() {
    var moveTree = MoveTree(firstSideToMove: .black)
    let minimum = MoveTree.Index.getMinimum(for: .black)
    let position = Position(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR b KQkq - 0 1")! //Starting position, but black makes the first move
    let e5 = Move(san: "e5", position: position)
    moveTree[minimum.next] = e5
    XCTAssertNotNil(moveTree.dictionary[minimum.next]?.hashValue)
  }

  func testSameVariationComparability() {
    let wIndex = MoveTree.Index(number: 4, color: .white, variation: 2)
    XCTAssertLessThan(wIndex, wIndex.next)
    XCTAssertGreaterThan(wIndex, wIndex.previous)

    let bIndex = MoveTree.Index(number: 4, color: .black, variation: 2)
    XCTAssertLessThan(bIndex, bIndex.next)
    XCTAssertGreaterThan(bIndex, bIndex.previous)
  }

  func testDifferentVariationComparability() {
    let wIndex1 = MoveTree.Index(number: 4, color: .white, variation: 2)
    let wIndex2 = MoveTree.Index(number: 4, color: .white, variation: 3)
    XCTAssertGreaterThan(wIndex1, wIndex2)
    XCTAssertGreaterThan(wIndex1.next, wIndex2.next)
    XCTAssertGreaterThan(wIndex1.previous, wIndex2.next)
    XCTAssertGreaterThan(wIndex1.next, wIndex2.previous)
    XCTAssertGreaterThan(wIndex1.previous, wIndex2.previous)

    let bIndex1 = MoveTree.Index(number: 4, color: .black, variation: 2)
    let bIndex2 = MoveTree.Index(number: 4, color: .black, variation: 3)
    XCTAssertGreaterThan(bIndex1, bIndex2)
    XCTAssertGreaterThan(bIndex1.next, bIndex2.next)
    XCTAssertGreaterThan(bIndex1.previous, bIndex2.next)
    XCTAssertGreaterThan(bIndex1.next, bIndex2.previous)
    XCTAssertGreaterThan(bIndex1.previous, bIndex2.previous)
  }

}

// MARK: - Deprecated Tests

extension MoveTreeTests {

  @available(*, deprecated)
  func testDeprecated() {
    var moveTree = MoveTree()
    let minimum = MoveTree.Index.getMinimum()

    let move1 = Move(san: "e4", position: .standard)!
    let move2 = Move(san: "e5", position: .init(fen: "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 2")!)!

    let i1 = MoveTree.Index(number: 1, color: .white)
    let i2 = MoveTree.Index(number: 1, color: .black)

    moveTree.add(move: move1)
    moveTree.add(move: move2, toParentIndex: i1)

    XCTAssertEqual(moveTree.previousIndex(for: i1), moveTree.index(before: i1))
    XCTAssertEqual(moveTree.nextIndex(for: i1), moveTree.index(after: i1))

    XCTAssertEqual(moveTree.move(at: i1), moveTree[i1])
    XCTAssertEqual(moveTree.move(at: i1), move1)

    XCTAssertEqual(moveTree.move(at: i2), moveTree[i2])
    XCTAssertEqual(moveTree.move(at: i2), move2)

    XCTAssertNil(moveTree.previousIndex(for: minimum))
    XCTAssertNil(moveTree.nextIndex(for: i2))

    XCTAssertEqual(moveTree.nextIndex(for: minimum), i1)
  }

}
