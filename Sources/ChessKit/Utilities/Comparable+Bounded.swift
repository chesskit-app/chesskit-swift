//
//  Comparable+Bounded.swift
//  ChessKit
//

extension Comparable {
    func bounded(by limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
