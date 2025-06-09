//
//  Stack.swift
//  ChessKit
//

struct Stack<T> {
  private var top: Node<T>?

  mutating func push(_ value: T) {
    let temp = top
    top = Node(value)
    top?.next = temp
  }

  @discardableResult
  mutating func pop() -> T? {
    defer { top = top?.next }
    return top?.value
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
