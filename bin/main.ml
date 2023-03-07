open Lexer

let () = 
  let fileName = "exemples/coffe.txt" in
  let lines = lex fileName in
  let _, actions, tests = lines in
  let () = printLines actions in
  printLines tests