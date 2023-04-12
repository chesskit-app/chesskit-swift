//
//  Comparable+Bounded.swift
//  ChessKit
//

extension Comparable {
    func bounded(by limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
