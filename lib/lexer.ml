type position = int * int
type token =
  | ARROW of position
  | COLON of position
  | COMMA of position
  | NEWLINE of position
  | LITERAL of position * string

type line =
  | Init of (int * int) * string
  | Test of int * (string list) * string
  | Action of int * string * string * string
  | Node of int * string

exception SyntaxError of position * string

let displayError file (line, column) message =
  let file = open_in file in
  let rec displayLine line =
    if line = 1 then
      let lineString = input_line file in
      Printf.printf "%s" lineString, String.length lineString
    else
      let _ = input_line file in
      displayLine (line - 1)
  in let () = Printf.printf "Error : %s\n" message
  in let _, l = displayLine line
  in let () =  if column <> -1 then
    Printf.printf "\n%s^\n" (String.make column ' ')
  else 
    Printf.printf "\n%s\n" (String.make l '^')
  in close_in file
  
let nextIs lineString column char =
  if String.length lineString <= column + 1 then
    false
  else
    String.get lineString (column + 1) = char

let rec parseLiteral lineString column acc =
  if String.length lineString <= column then
    String.concat "" (List.rev acc), column
  else match String.get lineString column with
  | 'a'..'z' | '0'..'9' | '_' -> parseLiteral lineString (column + 1) ((String.make 1 (String.get lineString column))::acc)
  | _ -> String.concat "" (List.rev acc), column

let appendNewLine line column = function
  | [] -> [NEWLINE (line, column)]
  | NEWLINE _::_  as acc -> acc
  | acc -> NEWLINE (line, column)::acc

let rec parseLine lineString line column acc =
  if String.length lineString <= column then
    appendNewLine line column acc
  else match String.get lineString column with
  | ' ' | '\r' -> parseLine lineString line (column + 1) acc
  | ':' -> parseLine lineString line (column + 1) (COLON (line, column)::acc)
  | '-' -> 
    if nextIs lineString column '>' then 
      parseLine lineString line (column + 2) (ARROW (line, column)::acc )
    else
      raise (SyntaxError ((line, column), "Unexpected character, missing > after -"))
  | ',' -> parseLine lineString line (column + 1) (COMMA (line, column)::acc)
  | 'a'..'z' | '0'..'9' | '_' -> 
    let literal, literalEnd = parseLiteral lineString column [] in
    parseLine lineString line literalEnd (LITERAL ((line, column), literal)::acc)
  | '#' -> appendNewLine line column acc
  | _ -> raise (SyntaxError ((line, column), "Unexpected character"))

let parse file =
  let file = open_in file in
  let rec parseLines line acc =
    try
      let lineString = input_line file in
      parseLines (line + 1) (parseLine lineString line 0 acc)
    with End_of_file -> List.rev acc
  in parseLines 1 []

let rec printTokens = function
| [] -> ()
| token::tokens ->
  let () = match token with
  | ARROW (line, column) -> Printf.printf "(%s, %d %d)" "ARROW" line column
  | COLON (line, column) -> Printf.printf "(%s, %d %d)" "COLON" line column
  | COMMA (line, column) -> Printf.printf "(%s, %d %d)" "COMMA" line column
  | NEWLINE (line, column) -> Printf.printf "(%s, %d %d)\n" "NEWLINE" line column
  | LITERAL ((line, column), literal) -> Printf.printf "(%s, %d %d)" ("LITERAL->" ^ literal) line column
in printTokens tokens

let parseStartPoint line tokens =
  if List.length tokens < 2 then
    raise (SyntaxError ((line, -1), "Not enough tokens"))
  else match tokens with
  | LITERAL ((line, column), literal)::tail -> Init ((line, column), literal), tail
  | COMMA(line, column)::_ | ARROW(line, column)::_ | COLON(line, column)::_ -> raise (SyntaxError ((line, column), "Unexpected token"))
  | NEWLINE(line, column)::_ -> raise (SyntaxError ((line, column + 2), "Expected literal after ->"))
  | [] -> failwith "This should not append"

let rec parseTest line acc lastLiteral = function
  | [] -> 
    if lastLiteral then
      raise (SyntaxError ((line, -1), "Expected comma or -> after literal"))
    else
      raise (SyntaxError ((line, -1), "Expected literal after comma, : or ->"))
  | (LITERAL ((_, _), literal))::tail -> parseTest line (literal::acc) true tail
  | (COMMA (line, column))::tail -> 
    if not lastLiteral then 
      raise (SyntaxError ((line, column), "Expected literal after comma"))
    else 
      parseTest column acc false tail
  | (ARROW _)::(LITERAL ((line, _), literal))::tail -> Test (line, List.rev acc, literal), tail
  | (ARROW (line, column))::_ -> raise (SyntaxError ((line, column + 2), "Expected literal after ->"))
  | NEWLINE(line, column)::_ -> raise (SyntaxError ((line, column), "Unexpected newline"))
  | (COLON (line, column))::_ -> raise (SyntaxError ((line, column), "Unexpected colon"))

let parseAction line tokens =
  if List.length tokens < 5 then
    raise (SyntaxError ((line, -1), "Not enough tokens"))
  else match tokens with
  | LITERAL ((line, _), literal)::(COLON _)::(LITERAL ((_, _), literal2))::(ARROW _)::(LITERAL ((_, _), literal3))::tail -> Action (line, literal, literal2, literal3), tail
  | _ -> raise (SyntaxError ((line, -1), "Action must be of the form literal:literal->literal"))

let rec lexAux acc = function
  | [] | (NEWLINE _)::[] -> let init, actions, tests = acc in (init, actions, List.rev tests)
  | (NEWLINE _)::l -> begin
    let init, actions, tests = acc in
    match l with
    | (COLON (line,_))::tail -> let test, rest = parseTest line [] false tail in lexAux (init, actions, test::tests) rest
    | (LITERAL ((line, _), literal))::((NEWLINE _)::_ as tail) -> lexAux (init, (Node(line,literal))::actions, tests) tail
    | (LITERAL ((line, _), _))::_ as l -> let action, rest = parseAction line l in lexAux (init, action::actions, tests) rest
    | (ARROW (line,_))::tail -> 
      if init = None then
        let startPoint, rest = parseStartPoint line tail in lexAux (Some(startPoint), actions, tests) rest
      else
        raise (SyntaxError ((line, -1), "You can only define one start node"))
    | (COMMA _)::_ -> failwith "Unexpected comma"
    | (NEWLINE (line, _))::_ -> Printf.eprintf "Unexpected newline at line %d" line; exit 1
    | _ -> failwith "This should not append"
  end
  | _ -> failwith "Expected newline token"

let lex file =
  let tokens = parse file in
  try
    let init, actions, tests = lexAux (None,[],[]) (appendNewLine 0 0 tokens)
    in if init = None then
      let () = Printf.eprintf "You must define a start node" in exit 1
    else
      Option.get init, actions, tests
  with SyntaxError(pos, message) ->
    let () = displayError file pos message in exit 1

let rec printLines = function
  | [] -> ()
  | line::lines -> let () = begin
    match line with
    | Init ((line, column), literal) -> Printf.printf "%d %d Init automaton at %s\n" line column literal
    | Test (line, literals, literal) -> Printf.printf "%d Test Take %s and expect %s\n" line (String.concat ", " literals) literal
    | Action (line, literal, literal2, literal3) -> Printf.printf "%d Action from %s if %s goto %s\n" line literal literal2 literal3
    | Node (line, literal) -> Printf.printf "%d Final node %s\n" line literal
  end in printLines lines
