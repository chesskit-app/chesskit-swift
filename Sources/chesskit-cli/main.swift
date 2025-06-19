//
//  main.swift
//  ChessKit
//

var cli = CLI()
cli.startUp()

while true {
  print(">> ", terminator: "")
  guard let input = readLine(), !input.isEmpty else {
    continue
  }

  if cli.process(input: input) == .quit {
    break
  }
}
