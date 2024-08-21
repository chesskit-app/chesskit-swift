//
//  SquareTests.swift
//  ChessKitTests
//

@testable import ChessKit
import XCTest

final class SquareTests: XCTestCase {

    func testNotation() {
        XCTAssertEqual(Square.a1.notation, "a1")
        XCTAssertEqual(Square.h1.notation, "h1")
        XCTAssertEqual(Square.a8.notation, "a8")
        XCTAssertEqual(Square.h8.notation, "h8")

        XCTAssertEqual(Square("a1"), .a1)
        XCTAssertEqual(Square("h1"), .h1)
        XCTAssertEqual(Square("a8"), .a8)
        XCTAssertEqual(Square("h8"), .h8)
    }

    func testInvalidNotation() {
        XCTAssertEqual(Square("invalid"), .a1)
    }

    func testSquareColor() {
        XCTAssertEqual(Square.a1.color, .dark)
        XCTAssertEqual(Square.h1.color, .light)
        XCTAssertEqual(Square.a8.color, .light)
        XCTAssertEqual(Square.h8.color, .dark)
    }

    func testFileNumber() {
        XCTAssertEqual(Square.File.a.number, 1)
        XCTAssertEqual(Square.File.h.number, 8)

        XCTAssertEqual(Square.File(1), .a)
        XCTAssertEqual(Square.File(2), .b)
        XCTAssertEqual(Square.File(3), .c)
        XCTAssertEqual(Square.File(4), .d)
        XCTAssertEqual(Square.File(5), .e)
        XCTAssertEqual(Square.File(6), .f)
        XCTAssertEqual(Square.File(7), .g)
        XCTAssertEqual(Square.File(8), .h)
    }

    func testInvalidFileNumber() {
        XCTAssertEqual(Square.File(-10), .a)
        XCTAssertEqual(Square.File(100), .h)
    }

    func testDirectionalSquares() {
        XCTAssertEqual(Square.a1.left, .a1)
        XCTAssertEqual(Square.b1.left, .a1)
        XCTAssertEqual(Square.h1.left, .g1)

        XCTAssertEqual(Square.a1.right, .b1)
        XCTAssertEqual(Square.g1.right, .h1)
        XCTAssertEqual(Square.h1.right, .h1)

        XCTAssertEqual(Square.a8.up, .a8)
        XCTAssertEqual(Square.a7.up, .a8)
        XCTAssertEqual(Square.a1.up, .a2)

        XCTAssertEqual(Square.a1.down, .a1)
        XCTAssertEqual(Square.a2.down, .a1)
        XCTAssertEqual(Square.a8.down, .a7)
    }

}
