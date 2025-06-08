//
//  Stack.swift
//  ChessKit
//

struct Stack<T> {
  private var top: Node<T>?

  mutating func push(_ value: T) {
    let currentTop = top
    top = Node(value)
    top?.next = currentTop
  }

  @discardableResult
  mutating func pop() -> T? {
    let currentTop = top
    top = top?.next
    return currentTop?.value
  }
}

extension Stack {
  private class Node<V> {
    let value: V
    var next: Node?

    init(_ value: V) {
      self.value = value
    }
  }
}
