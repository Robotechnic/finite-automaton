open Lexer

let () = 
  let fileName = "exemples/coffe.txt" in
  let lines = lex fileName in
  printLines lines