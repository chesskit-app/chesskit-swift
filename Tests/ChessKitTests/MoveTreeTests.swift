//
//  MoveTreeTests.swift
//  ChessKitTests
//

@testable import ChessKit
import Testing

struct MoveTreeTests {

  @Test func emptyCollection() {
    let moveTree = MoveTree()
    #expect(moveTree.isEmpty)
    #expect(moveTree.startIndex == .minimum)
    #expect(moveTree.endIndex == .minimum)

    #expect(!moveTree.hasIndex(before: .minimum))
    #expect(!moveTree.hasIndex(after: .minimum))
  }

  @Test func subscriptAccess() {
    var moveTree = MoveTree()
    #expect(moveTree[.minimum] == nil)

    let e4 = Move(san: "e4", position: .standard)
    moveTree[.minimum.next] = e4
    #expect(moveTree[.minimum.next] == e4)
  }

  @Test func ndeHashValue() {
    var moveTree = MoveTree()
    let e4 = Move(san: "e4", position: .standard)
    moveTree[.minimum.next] = e4
    #expect(moveTree.dictionary[.minimum.next]?.hashValue != nil)
  }

  @Test func sameVariationComparability() {
    let wIndex = MoveTree.Index(number: 4, color: .white, variation: 2)
    #expect(wIndex < wIndex.next)
    #expect(wIndex > wIndex.previous)

    let bIndex = MoveTree.Index(number: 4, color: .black, variation: 2)
    #expect(bIndex < bIndex.next)
    #expect(bIndex > bIndex.previous)
  }

  @Test func differentVariationComparability() {
    let wIndex1 = MoveTree.Index(number: 4, color: .white, variation: 2)
    let wIndex2 = MoveTree.Index(number: 4, color: .white, variation: 3)
    #expect(wIndex1 > wIndex2)
    #expect(wIndex1.next > wIndex2.next)
    #expect(wIndex1.previous > wIndex2.next)
    #expect(wIndex1.next > wIndex2.previous)
    #expect(wIndex1.previous > wIndex2.previous)

    let bIndex1 = MoveTree.Index(number: 4, color: .black, variation: 2)
    let bIndex2 = MoveTree.Index(number: 4, color: .black, variation: 3)
    #expect(bIndex1 > bIndex2)
    #expect(bIndex1.next > bIndex2.next)
    #expect(bIndex1.previous > bIndex2.next)
    #expect(bIndex1.next > bIndex2.previous)
    #expect(bIndex1.previous > bIndex2.previous)
  }

  @Test func nonexistentIndexBeforeAndAfter() {
    let tree = MoveTree()
    #expect(tree.index(after: .minimum) == .minimum)
    #expect(tree.index(before: .minimum) == .minimum)
  }

}

// MARK: - Deprecated Tests

extension MoveTreeTests {

  @available(*, deprecated)
  @Test func deprecated() {
    var moveTree = MoveTree()

    let move1 = Move(san: "e4", position: .standard)!
    let move2 = Move(san: "e5", position: .init(fen: "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 2")!)!

    let i1 = MoveTree.Index(number: 1, color: .white)
    let i2 = MoveTree.Index(number: 1, color: .black)

    moveTree.add(move: move1)
    moveTree.add(move: move2, toParentIndex: i1)

    #expect(moveTree.previousIndex(for: i1) == moveTree.index(before: i1))
    #expect(moveTree.nextIndex(for: i1) == moveTree.index(after: i1))

    #expect(moveTree.move(at: i1) == moveTree[i1])
    #expect(moveTree.move(at: i1) == move1)

    #expect(moveTree.move(at: i2) == moveTree[i2])
    #expect(moveTree.move(at: i2) == move2)

    #expect(moveTree.previousIndex(for: .minimum) == nil)
    #expect(moveTree.nextIndex(for: i2) == nil)

    #expect(moveTree.nextIndex(for: .minimum) == i1)
  }

}
