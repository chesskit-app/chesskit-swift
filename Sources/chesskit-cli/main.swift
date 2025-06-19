//
//  main.swift
//  ChessKit
//

var cli = CLI()
cli.startUp()

runLoop: while true {
  print(">> ", terminator: "")
  guard let input = readLine(), !input.isEmpty else { continue }

  if cli.process(input: input) == .exit {
    break runLoop
  }
}
