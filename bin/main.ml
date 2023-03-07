open Lexer

let () = 
  let fileName = "exemples/coffee.txt" in
  let lines = lex fileName in
  let base, actions, tests = lines in
  let () = GraphvizExport.export "coffee.dot" base actions in
  let coffee = Automaton.buildAutomaton base actions in
  Automaton.runTests coffee tests