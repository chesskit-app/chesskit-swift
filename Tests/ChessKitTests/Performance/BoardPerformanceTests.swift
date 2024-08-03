//
//  BoardPerformanceTests.swift
//  ChessKitTests
//

@testable import ChessKit
import XCTest

final class BoardPerformanceTests: XCTestCase {

    func testBoardPerformance() {
        measure(
            metrics: [
                XCTClockMetric(),
                XCTCPUMetric(),
                XCTMemoryMetric()
            ],
            block: simulateGame
        )
    }

    private func simulateGame() {
        var board = Board()

        board.move(pieceAt: .e2, to: .e4)
        XCTAssertEqual(board.position.fen, "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")

        board.move(pieceAt: .e7, to: .e5)
        XCTAssertEqual(board.position.fen, "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2")

        board.move(pieceAt: .g1, to: .f3)
        XCTAssertEqual(board.position.fen, "rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2")

        board.move(pieceAt: .b8, to: .c6)
        XCTAssertEqual(board.position.fen, "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3")

        board.move(pieceAt: .f1, to: .b5)
        XCTAssertEqual(board.position.fen, "r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3")

        board.move(pieceAt: .a7, to: .a6)
        XCTAssertEqual(board.position.fen, "r1bqkbnr/1ppp1ppp/p1n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 0 4")

        board.move(pieceAt: .b5, to: .a4)
        XCTAssertEqual(board.position.fen, "r1bqkbnr/1ppp1ppp/p1n5/4p3/B3P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 1 4")

        board.move(pieceAt: .g8, to: .f6)
        XCTAssertEqual(board.position.fen, "r1bqkb1r/1ppp1ppp/p1n2n2/4p3/B3P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 2 5")

        board.move(pieceAt: .e1, to: .g1)
        XCTAssertEqual(board.position.fen, "r1bqkb1r/1ppp1ppp/p1n2n2/4p3/B3P3/5N2/PPPP1PPP/RNBQ1RK1 b kq - 3 5")

        board.move(pieceAt: .f8, to: .e7)
        XCTAssertEqual(board.position.fen, "r1bqk2r/1pppbppp/p1n2n2/4p3/B3P3/5N2/PPPP1PPP/RNBQ1RK1 w kq - 4 6")

        board.move(pieceAt: .f1, to: .e1)
        XCTAssertEqual(board.position.fen, "r1bqk2r/1pppbppp/p1n2n2/4p3/B3P3/5N2/PPPP1PPP/RNBQR1K1 b kq - 5 6")

        board.move(pieceAt: .b7, to: .b5)
        XCTAssertEqual(board.position.fen, "r1bqk2r/2ppbppp/p1n2n2/1p2p3/B3P3/5N2/PPPP1PPP/RNBQR1K1 w kq b6 0 7")

        board.move(pieceAt: .a4, to: .b3)
        XCTAssertEqual(board.position.fen, "r1bqk2r/2ppbppp/p1n2n2/1p2p3/4P3/1B3N2/PPPP1PPP/RNBQR1K1 b kq - 1 7")

        board.move(pieceAt: .d7, to: .d6)
        XCTAssertEqual(board.position.fen, "r1bqk2r/2p1bppp/p1np1n2/1p2p3/4P3/1B3N2/PPPP1PPP/RNBQR1K1 w kq - 0 8")

        board.move(pieceAt: .c2, to: .c3)
        XCTAssertEqual(board.position.fen, "r1bqk2r/2p1bppp/p1np1n2/1p2p3/4P3/1BP2N2/PP1P1PPP/RNBQR1K1 b kq - 0 8")

        board.move(pieceAt: .e8, to: .g8)
        XCTAssertEqual(board.position.fen, "r1bq1rk1/2p1bppp/p1np1n2/1p2p3/4P3/1BP2N2/PP1P1PPP/RNBQR1K1 w - - 1 9")

        board.move(pieceAt: .h2, to: .h3)
        XCTAssertEqual(board.position.fen, "r1bq1rk1/2p1bppp/p1np1n2/1p2p3/4P3/1BP2N1P/PP1P1PP1/RNBQR1K1 b - - 0 9")

        board.move(pieceAt: .c6, to: .b8)
        XCTAssertEqual(board.position.fen, "rnbq1rk1/2p1bppp/p2p1n2/1p2p3/4P3/1BP2N1P/PP1P1PP1/RNBQR1K1 w - - 1 10")

        board.move(pieceAt: .d2, to: .d4)
        XCTAssertEqual(board.position.fen, "rnbq1rk1/2p1bppp/p2p1n2/1p2p3/3PP3/1BP2N1P/PP3PP1/RNBQR1K1 b - d3 0 10")

        board.move(pieceAt: .b8, to: .d7)
        XCTAssertEqual(board.position.fen, "r1bq1rk1/2pnbppp/p2p1n2/1p2p3/3PP3/1BP2N1P/PP3PP1/RNBQR1K1 w - - 1 11")

        board.move(pieceAt: .c3, to: .c4)
        XCTAssertEqual(board.position.fen, "r1bq1rk1/2pnbppp/p2p1n2/1p2p3/2PPP3/1B3N1P/PP3PP1/RNBQR1K1 b - - 0 11")

        board.move(pieceAt: .c7, to: .c6)
        XCTAssertEqual(board.position.fen, "r1bq1rk1/3nbppp/p1pp1n2/1p2p3/2PPP3/1B3N1P/PP3PP1/RNBQR1K1 w - - 0 12")

        board.move(pieceAt: .c4, to: .b5)
        XCTAssertEqual(board.position.fen, "r1bq1rk1/3nbppp/p1pp1n2/1P2p3/3PP3/1B3N1P/PP3PP1/RNBQR1K1 b - - 0 12")

        board.move(pieceAt: .a6, to: .b5)
        XCTAssertEqual(board.position.fen, "r1bq1rk1/3nbppp/2pp1n2/1p2p3/3PP3/1B3N1P/PP3PP1/RNBQR1K1 w - - 0 13")

        board.move(pieceAt: .b1, to: .c3)
        XCTAssertEqual(board.position.fen, "r1bq1rk1/3nbppp/2pp1n2/1p2p3/3PP3/1BN2N1P/PP3PP1/R1BQR1K1 b - - 1 13")

        board.move(pieceAt: .c8, to: .b7)
        XCTAssertEqual(board.position.fen, "r2q1rk1/1b1nbppp/2pp1n2/1p2p3/3PP3/1BN2N1P/PP3PP1/R1BQR1K1 w - - 2 14")

        board.move(pieceAt: .c1, to: .g5)
        XCTAssertEqual(board.position.fen, "r2q1rk1/1b1nbppp/2pp1n2/1p2p1B1/3PP3/1BN2N1P/PP3PP1/R2QR1K1 b - - 3 14")

        board.move(pieceAt: .b5, to: .b4)
        XCTAssertEqual(board.position.fen, "r2q1rk1/1b1nbppp/2pp1n2/4p1B1/1p1PP3/1BN2N1P/PP3PP1/R2QR1K1 w - - 0 15")

        board.move(pieceAt: .c3, to: .b1)
        XCTAssertEqual(board.position.fen, "r2q1rk1/1b1nbppp/2pp1n2/4p1B1/1p1PP3/1B3N1P/PP3PP1/RN1QR1K1 b - - 1 15")

        board.move(pieceAt: .h7, to: .h6)
        XCTAssertEqual(board.position.fen, "r2q1rk1/1b1nbpp1/2pp1n1p/4p1B1/1p1PP3/1B3N1P/PP3PP1/RN1QR1K1 w - - 0 16")

        board.move(pieceAt: .g5, to: .h4)
        XCTAssertEqual(board.position.fen, "r2q1rk1/1b1nbpp1/2pp1n1p/4p3/1p1PP2B/1B3N1P/PP3PP1/RN1QR1K1 b - - 1 16")

        board.move(pieceAt: .c6, to: .c5)
        XCTAssertEqual(board.position.fen, "r2q1rk1/1b1nbpp1/3p1n1p/2p1p3/1p1PP2B/1B3N1P/PP3PP1/RN1QR1K1 w - - 0 17")

        board.move(pieceAt: .d4, to: .e5)
        XCTAssertEqual(board.position.fen, "r2q1rk1/1b1nbpp1/3p1n1p/2p1P3/1p2P2B/1B3N1P/PP3PP1/RN1QR1K1 b - - 0 17")

        board.move(pieceAt: .f6, to: .e4)
        XCTAssertEqual(board.position.fen, "r2q1rk1/1b1nbpp1/3p3p/2p1P3/1p2n2B/1B3N1P/PP3PP1/RN1QR1K1 w - - 0 18")

        board.move(pieceAt: .h4, to: .e7)
        XCTAssertEqual(board.position.fen, "r2q1rk1/1b1nBpp1/3p3p/2p1P3/1p2n3/1B3N1P/PP3PP1/RN1QR1K1 b - - 0 18")

        board.move(pieceAt: .d8, to: .e7)
        XCTAssertEqual(board.position.fen, "r4rk1/1b1nqpp1/3p3p/2p1P3/1p2n3/1B3N1P/PP3PP1/RN1QR1K1 w - - 0 19")

        board.move(pieceAt: .e5, to: .d6)
        XCTAssertEqual(board.position.fen, "r4rk1/1b1nqpp1/3P3p/2p5/1p2n3/1B3N1P/PP3PP1/RN1QR1K1 b - - 0 19")

        board.move(pieceAt: .e7, to: .f6)
        XCTAssertEqual(board.position.fen, "r4rk1/1b1n1pp1/3P1q1p/2p5/1p2n3/1B3N1P/PP3PP1/RN1QR1K1 w - - 1 20")

        board.move(pieceAt: .b1, to: .d2)
        XCTAssertEqual(board.position.fen, "r4rk1/1b1n1pp1/3P1q1p/2p5/1p2n3/1B3N1P/PP1N1PP1/R2QR1K1 b - - 2 20")

        board.move(pieceAt: .e4, to: .d6)
        XCTAssertEqual(board.position.fen, "r4rk1/1b1n1pp1/3n1q1p/2p5/1p6/1B3N1P/PP1N1PP1/R2QR1K1 w - - 0 21")

        board.move(pieceAt: .d2, to: .c4)
        XCTAssertEqual(board.position.fen, "r4rk1/1b1n1pp1/3n1q1p/2p5/1pN5/1B3N1P/PP3PP1/R2QR1K1 b - - 1 21")

        board.move(pieceAt: .d6, to: .c4)
        XCTAssertEqual(board.position.fen, "r4rk1/1b1n1pp1/5q1p/2p5/1pn5/1B3N1P/PP3PP1/R2QR1K1 w - - 0 22")

        board.move(pieceAt: .b3, to: .c4)
        XCTAssertEqual(board.position.fen, "r4rk1/1b1n1pp1/5q1p/2p5/1pB5/5N1P/PP3PP1/R2QR1K1 b - - 0 22")

        board.move(pieceAt: .d7, to: .b6)
        XCTAssertEqual(board.position.fen, "r4rk1/1b3pp1/1n3q1p/2p5/1pB5/5N1P/PP3PP1/R2QR1K1 w - - 1 23")

        board.move(pieceAt: .f3, to: .e5)
        XCTAssertEqual(board.position.fen, "r4rk1/1b3pp1/1n3q1p/2p1N3/1pB5/7P/PP3PP1/R2QR1K1 b - - 2 23")

        board.move(pieceAt: .a8, to: .e8)
        XCTAssertEqual(board.position.fen, "4rrk1/1b3pp1/1n3q1p/2p1N3/1pB5/7P/PP3PP1/R2QR1K1 w - - 3 24")

        board.move(pieceAt: .c4, to: .f7)
        XCTAssertEqual(board.position.fen, "4rrk1/1b3Bp1/1n3q1p/2p1N3/1p6/7P/PP3PP1/R2QR1K1 b - - 0 24")

        board.move(pieceAt: .f8, to: .f7)
        XCTAssertEqual(board.position.fen, "4r1k1/1b3rp1/1n3q1p/2p1N3/1p6/7P/PP3PP1/R2QR1K1 w - - 0 25")

        board.move(pieceAt: .e5, to: .f7)
        XCTAssertEqual(board.position.fen, "4r1k1/1b3Np1/1n3q1p/2p5/1p6/7P/PP3PP1/R2QR1K1 b - - 0 25")

        board.move(pieceAt: .e8, to: .e1)
        XCTAssertEqual(board.position.fen, "6k1/1b3Np1/1n3q1p/2p5/1p6/7P/PP3PP1/R2Qr1K1 w - - 0 26")

        board.move(pieceAt: .d1, to: .e1)
        XCTAssertEqual(board.position.fen, "6k1/1b3Np1/1n3q1p/2p5/1p6/7P/PP3PP1/R3Q1K1 b - - 0 26")

        board.move(pieceAt: .g8, to: .f7)
        XCTAssertEqual(board.position.fen, "8/1b3kp1/1n3q1p/2p5/1p6/7P/PP3PP1/R3Q1K1 w - - 0 27")

        board.move(pieceAt: .e1, to: .e3)
        XCTAssertEqual(board.position.fen, "8/1b3kp1/1n3q1p/2p5/1p6/4Q2P/PP3PP1/R5K1 b - - 1 27")

        board.move(pieceAt: .f6, to: .g5)
        XCTAssertEqual(board.position.fen, "8/1b3kp1/1n5p/2p3q1/1p6/4Q2P/PP3PP1/R5K1 w - - 2 28")

        board.move(pieceAt: .e3, to: .g5)
        XCTAssertEqual(board.position.fen, "8/1b3kp1/1n5p/2p3Q1/1p6/7P/PP3PP1/R5K1 b - - 0 28")

        board.move(pieceAt: .h6, to: .g5)
        XCTAssertEqual(board.position.fen, "8/1b3kp1/1n6/2p3p1/1p6/7P/PP3PP1/R5K1 w - - 0 29")

        board.move(pieceAt: .b2, to: .b3)
        XCTAssertEqual(board.position.fen, "8/1b3kp1/1n6/2p3p1/1p6/1P5P/P4PP1/R5K1 b - - 0 29")

        board.move(pieceAt: .f7, to: .e6)
        XCTAssertEqual(board.position.fen, "8/1b4p1/1n2k3/2p3p1/1p6/1P5P/P4PP1/R5K1 w - - 1 30")

        board.move(pieceAt: .a2, to: .a3)
        XCTAssertEqual(board.position.fen, "8/1b4p1/1n2k3/2p3p1/1p6/PP5P/5PP1/R5K1 b - - 0 30")

        board.move(pieceAt: .e6, to: .d6)
        XCTAssertEqual(board.position.fen, "8/1b4p1/1n1k4/2p3p1/1p6/PP5P/5PP1/R5K1 w - - 1 31")

        board.move(pieceAt: .a3, to: .b4)
        XCTAssertEqual(board.position.fen, "8/1b4p1/1n1k4/2p3p1/1P6/1P5P/5PP1/R5K1 b - - 0 31")

        board.move(pieceAt: .c5, to: .b4)
        XCTAssertEqual(board.position.fen, "8/1b4p1/1n1k4/6p1/1p6/1P5P/5PP1/R5K1 w - - 0 32")

        board.move(pieceAt: .a1, to: .a5)
        XCTAssertEqual(board.position.fen, "8/1b4p1/1n1k4/R5p1/1p6/1P5P/5PP1/6K1 b - - 1 32")

        board.move(pieceAt: .b6, to: .d5)
        XCTAssertEqual(board.position.fen, "8/1b4p1/3k4/R2n2p1/1p6/1P5P/5PP1/6K1 w - - 2 33")

        board.move(pieceAt: .f2, to: .f3)
        XCTAssertEqual(board.position.fen, "8/1b4p1/3k4/R2n2p1/1p6/1P3P1P/6P1/6K1 b - - 0 33")

        board.move(pieceAt: .b7, to: .c8)
        XCTAssertEqual(board.position.fen, "2b5/6p1/3k4/R2n2p1/1p6/1P3P1P/6P1/6K1 w - - 1 34")

        board.move(pieceAt: .g1, to: .f2)
        XCTAssertEqual(board.position.fen, "2b5/6p1/3k4/R2n2p1/1p6/1P3P1P/5KP1/8 b - - 2 34")

        board.move(pieceAt: .c8, to: .f5)
        XCTAssertEqual(board.position.fen, "8/6p1/3k4/R2n1bp1/1p6/1P3P1P/5KP1/8 w - - 3 35")

        board.move(pieceAt: .a5, to: .a7)
        XCTAssertEqual(board.position.fen, "8/R5p1/3k4/3n1bp1/1p6/1P3P1P/5KP1/8 b - - 4 35")

        board.move(pieceAt: .g7, to: .g6)
        XCTAssertEqual(board.position.fen, "8/R7/3k2p1/3n1bp1/1p6/1P3P1P/5KP1/8 w - - 0 36")

        board.move(pieceAt: .a7, to: .a6)
        XCTAssertEqual(board.position.fen, "8/8/R2k2p1/3n1bp1/1p6/1P3P1P/5KP1/8 b - - 1 36")

        board.move(pieceAt: .d6, to: .c5)
        XCTAssertEqual(board.position.fen, "8/8/R5p1/2kn1bp1/1p6/1P3P1P/5KP1/8 w - - 2 37")

        board.move(pieceAt: .f2, to: .e1)
        XCTAssertEqual(board.position.fen, "8/8/R5p1/2kn1bp1/1p6/1P3P1P/6P1/4K3 b - - 3 37")

        board.move(pieceAt: .d5, to: .f4)
        XCTAssertEqual(board.position.fen, "8/8/R5p1/2k2bp1/1p3n2/1P3P1P/6P1/4K3 w - - 4 38")

        board.move(pieceAt: .g2, to: .g3)
        XCTAssertEqual(board.position.fen, "8/8/R5p1/2k2bp1/1p3n2/1P3PPP/8/4K3 b - - 0 38")

        board.move(pieceAt: .f4, to: .h3)
        XCTAssertEqual(board.position.fen, "8/8/R5p1/2k2bp1/1p6/1P3PPn/8/4K3 w - - 0 39")

        board.move(pieceAt: .e1, to: .d2)
        XCTAssertEqual(board.position.fen, "8/8/R5p1/2k2bp1/1p6/1P3PPn/3K4/8 b - - 1 39")

        board.move(pieceAt: .c5, to: .b5)
        XCTAssertEqual(board.position.fen, "8/8/R5p1/1k3bp1/1p6/1P3PPn/3K4/8 w - - 2 40")

        board.move(pieceAt: .a6, to: .d6)
        XCTAssertEqual(board.position.fen, "8/8/3R2p1/1k3bp1/1p6/1P3PPn/3K4/8 b - - 3 40")

        board.move(pieceAt: .b5, to: .c5)
        XCTAssertEqual(board.position.fen, "8/8/3R2p1/2k2bp1/1p6/1P3PPn/3K4/8 w - - 4 41")

        board.move(pieceAt: .d6, to: .a6)
        XCTAssertEqual(board.position.fen, "8/8/R5p1/2k2bp1/1p6/1P3PPn/3K4/8 b - - 5 41")

        board.move(pieceAt: .h3, to: .f2)
        XCTAssertEqual(board.position.fen, "8/8/R5p1/2k2bp1/1p6/1P3PP1/3K1n2/8 w - - 6 42")
        
        board.move(pieceAt: .g3, to: .g4)
        XCTAssertEqual(board.position.fen, "8/8/R5p1/2k2bp1/1p4P1/1P3P2/3K1n2/8 b - - 0 42")

        board.move(pieceAt: .f5, to: .d3)
        XCTAssertEqual(board.position.fen, "8/8/R5p1/2k3p1/1p4P1/1P1b1P2/3K1n2/8 w - - 1 43")

        board.move(pieceAt: .a6, to: .e6)
        XCTAssertEqual(board.position.fen, "8/8/4R1p1/2k3p1/1p4P1/1P1b1P2/3K1n2/8 b - - 2 43")

        XCTAssertEqual(board.position.piece(at: .d2)?.kind, .king)
    }

}
