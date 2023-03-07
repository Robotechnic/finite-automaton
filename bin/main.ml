open Lexer

let () = 
  let fileName = "exemples/coffee.txt" in
  let lines = lex fileName in
  let base, actions, tests = lines in
  let coffee = Automaton.buildAutomaton base actions in
  Automaton.runTests coffee tests