//
//  BoardOperationTests.swift
//  ChessKitTests
//

import XCTest
@testable import ChessKit

class BoardOperationTests: XCTestCase {

    func testUpOperation() {
        let start = Square(.d, 5)
        let end = start ↑ 2

        XCTAssertEqual(end, Square(.d, 7))

        let startEdge = Square(.d, 8)
        let endEdge = startEdge ↑ 1

        XCTAssertEqual(startEdge, endEdge)
    }

    func testDownOperation() {
        let start = Square(.d, 5)
        let end = start ↓ 2

        XCTAssertEqual(end, Square(.d, 3))

        let startEdge = Square(.d, 1)
        let endEdge = startEdge ↓ 1

        XCTAssertEqual(startEdge, endEdge)
    }

    func testLeftOperation() {
        let start = Square(.d, 5)
        let end = start ← 2

        XCTAssertEqual(end, Square(.b, 5))

        let startEdge = Square(.a, 4)
        let endEdge = startEdge ← 1

        XCTAssertEqual(startEdge, endEdge)
    }

    func testRightOperation() {
        let start = Square(.d, 5)
        let end = start → 2

        XCTAssertEqual(end, Square(.f, 5))

        let startEdge = Square(.h, 4)
        let endEdge = startEdge → 1

        XCTAssertEqual(startEdge, endEdge)
    }

    func testNortheastOperation() {
        let start = Square(.d, 5)
        let end = start ↗ 2

        XCTAssertEqual(end, Square(.f, 7))

        let startEdge = Square(.d, 8)
        let endEdge = startEdge ↗ 1

        XCTAssertEqual(startEdge, endEdge)
    }

    func testNorthwestOperation() {
        let start = Square(.d, 5)
        let end = start ↖ 2

        XCTAssertEqual(end, Square(.b, 7))

        let startEdge = Square(.d, 8)
        let endEdge = startEdge ↖ 1

        XCTAssertEqual(startEdge, endEdge)
    }

    func testSoutheastOperation() {
        let start = Square(.d, 5)
        let end = start ↘ 2

        XCTAssertEqual(end, Square(.f, 3))

        let startEdge = Square(.d, 1)
        let endEdge = startEdge ↘ 1

        XCTAssertEqual(startEdge, endEdge)
    }

    func testSouthwestOperation() {
        let start = Square(.d, 5)
        let end = start ↙ 2

        XCTAssertEqual(end, Square(.b, 3))

        let startEdge = Square(.d, 1)
        let endEdge = startEdge ↙ 1

        XCTAssertEqual(startEdge, endEdge)
    }

    func testKnightOperationNNE() {
        let end = kNNE(start: Square(.d, 5))
        XCTAssertEqual(end, Square(.e, 7))

        let endEdge = kNNE(start: Square(.d, 8))
        XCTAssertNil(endEdge)
    }

    func testKnightOperationENE() {
        let end = kENE(start: Square(.d, 5))
        XCTAssertEqual(end, Square(.f, 6))

        let endEdge = kENE(start: Square(.d, 8))
        XCTAssertNil(endEdge)
    }

    func testKnightOperationESE() {
        let end = kESE(start: Square(.d, 5))
        XCTAssertEqual(end, Square(.f, 4))

        let endEdge = kESE(start: Square(.d, 1))
        XCTAssertNil(endEdge)
    }

    func testKnightOperationSSE() {
        let end = kSSE(start: Square(.d, 5))
        XCTAssertEqual(end, Square(.e, 3))

        let endEdge = kSSE(start: Square(.d, 1))
        XCTAssertNil(endEdge)
    }

    func testKnightOperationSSW() {
        let end = kSSW(start: Square(.d, 5))
        XCTAssertEqual(end, Square(.c, 3))

        let endEdge = kSSW(start: Square(.d, 1))
        XCTAssertNil(endEdge)
    }

    func testKnightOperationWSW() {
        let end = kWSW(start: Square(.d, 5))
        XCTAssertEqual(end, Square(.b, 4))

        let endEdge = kWSW(start: Square(.d, 1))
        XCTAssertNil(endEdge)
    }

    func testKnightOperationWNW() {
        let end = kWNW(start: Square(.d, 5))
        XCTAssertEqual(end, Square(.b, 6))

        let endEdge = kWNW(start: Square(.d, 8))
        XCTAssertNil(endEdge)
    }

    func testKnightOperationNNW() {
        let end = kNNW(start: Square(.d, 5))
        XCTAssertEqual(end, Square(.c, 7))

        let endEdge = kNNW(start: Square(.d, 8))
        XCTAssertNil(endEdge)
    }

}
