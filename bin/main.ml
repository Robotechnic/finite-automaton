open Lexer

let usageString = "Usage : " ^ Sys.argv.(0) ^ " [OPTIONS...] [FILE]"

let dotStream = ref stdout
let fileStream = ref stdin
let substeps = ref false
let tests : string list ref = ref []
let testMatch = Str.regexp "[A-Za-z0-9_]+"

let parseTest test =
  let splits = Str.split (Str.regexp ",") test in
  let rec checkTests = function
  | [] -> ()
  | h::t ->
    if not (Str.string_match testMatch h 0) then
      let () = Printf.eprintf "Error : %s is not a valid event" h in exit 1
    else
      checkTests t
  in let () = checkTests splits
  in tests := splits

let openStream openMethod ref fileName =
  try
    let stream = openMethod fileName in
    ref := stream
  with Sys_error msg ->
    Printf.eprintf "Error : %s" msg;
    exit 1

let options = [
  ("--dot", Arg.String (openStream open_out dotStream), "Export the automaton to a dot file");
  ("-s", Arg.Set substeps, "Display substeps of the automaton execution");
  ("-t", Arg.String parseTest, "Run the automaton on the given events, this wont run tests in the file");
]

let openAutomatonFile fileName =
  if !fileStream = stdin then
    openStream open_in fileStream fileName
  else
    let () = Printf.eprintf "Error : You can only open one file at the time" in exit 1

let () = 
  let () = Arg.parse options openAutomatonFile usageString in
  let baseState, events, fileTests = lex !fileStream in
  let () = if !dotStream != stdout then
    let () = GraphvizExport.export !dotStream baseState events
    in close_out !dotStream
  in let automaton = Automaton.buildAutomaton baseState events in
  if !tests = [] then
    Automaton.runTests automaton !substeps fileTests
  else
    print_endline (Automaton.getAutomatonState (Automaton.runAutomaton automaton !substeps !tests))

