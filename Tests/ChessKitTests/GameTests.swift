//
//  GameTests.swift
//  ChessKitTests
//

import XCTest
@testable import ChessKit

class GameTests: XCTestCase {
    
    func testAnnotation() {
        let game = Game(
            pgn: """
                1. e4 e5 2. Nf3 $2 Nc6 3. Bb5 a6
                4. Ba4 Nf6 5. O-O Be7 6. Re1 b5 7. Bb3 d6 8. c3 O-O 9. h3 Nb8 10. d4 Nbd7 $4
                11. c4 c6 12. cxb5 axb5 13. Nc3 Bb7 14. Bg5 b4 15. Nb1 h6 16. Bh4 c5 17. dxe5 Nxe4
                """
        )
        
        let assessment = Move.Assessment.good
        let comment = "This opening is called the Ruy Lopez."
        game?.annotate(moveAt: 3, color: .black, assessment: assessment, comment: comment)
        
        XCTAssertEqual(game?.moves[3]?.black?.assessment, assessment)
        XCTAssertEqual(game?.moves[3]?.black?.comment, comment)
    }
    
    
}
