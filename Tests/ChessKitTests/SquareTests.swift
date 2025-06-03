//
//  SquareTests.swift
//  ChessKitTests
//

@testable import ChessKit
import Testing

struct SquareTests {

  @Test func notation() {
    #expect(Square.a1.notation == "a1")
    #expect(Square.h1.notation == "h1")
    #expect(Square.a8.notation == "a8")
    #expect(Square.h8.notation == "h8")

    #expect(Square("a1") == .a1)
    #expect(Square("h1") == .h1)
    #expect(Square("a8") == .a8)
    #expect(Square("h8") == .h8)
  }

  @Test func invalidNotation() {
    #expect(Square("invalid") == .a1)
  }

  @Test func squareColor() {
    #expect(Square.a1.color == .dark)
    #expect(Square.h1.color == .light)
    #expect(Square.a8.color == .light)
    #expect(Square.h8.color == .dark)
  }

  @Test func fileNumber() {
    #expect(Square.File.a.number == 1)
    #expect(Square.File.h.number == 8)

    #expect(Square.File(1) == .a)
    #expect(Square.File(2) == .b)
    #expect(Square.File(3) == .c)
    #expect(Square.File(4) == .d)
    #expect(Square.File(5) == .e)
    #expect(Square.File(6) == .f)
    #expect(Square.File(7) == .g)
    #expect(Square.File(8) == .h)
  }

  @Test func invalidFileNumber() {
    #expect(Square.File(-10) == .a)
    #expect(Square.File(100) == .h)
  }

  @Test func directionalSquares() {
    #expect(Square.a1.left == .a1)
    #expect(Square.b1.left == .a1)
    #expect(Square.h1.left == .g1)

    #expect(Square.a1.right == .b1)
    #expect(Square.g1.right == .h1)
    #expect(Square.h1.right == .h1)

    #expect(Square.a8.up == .a8)
    #expect(Square.a7.up == .a8)
    #expect(Square.a1.up == .a2)

    #expect(Square.a1.down == .a1)
    #expect(Square.a2.down == .a1)
    #expect(Square.a8.down == .a7)
  }

}
