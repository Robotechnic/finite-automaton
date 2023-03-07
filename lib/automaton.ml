module AutomatonEvent = Map.Make(String)

type automaton = {
  state : string;
  events : (int * string AutomatonEvent.t) AutomatonEvent.t
}

(**
  Check if all events defined in the automaton actions exists in the automaton
*)
let checkAutomatonEvents map =
  let rec checkEvents line = function
  | [] -> ()
  | (_, endNode)::tails ->
    if not (AutomatonEvent.mem endNode map) then
      let () = Printf.eprintf "Error: End node \"%s\" defined at line %d does not exist in automaton" endNode line in exit 1
    else
      checkEvents line tails
    in AutomatonEvent.iter (fun _ (line, events) -> checkEvents line (AutomatonEvent.bindings events)) map

let buildAutomaton baseState events =
  match baseState with
  | Lexer.Action _ | Lexer.Test _ | Lexer.Node _ -> failwith "Base state must be a state"
  | Lexer.Init ((line, _), state) -> begin
    let rec buildEvents map = function
    | [] -> map
    | Lexer.Action(line, from, if_, to_)::tails ->
      if AutomatonEvent.mem from map then
        let events = AutomatonEvent.find from map in
        buildEvents (AutomatonEvent.add from (line, (AutomatonEvent.add if_ to_ (snd events))) map) tails
      else
        buildEvents (AutomatonEvent.add from (line, (AutomatonEvent.singleton if_ to_)) map) tails
    | Lexer.Node(line, literal)::tails -> 
      if AutomatonEvent.mem literal map then
        buildEvents map tails
      else
        buildEvents (AutomatonEvent.add literal (line, AutomatonEvent.empty) map) tails
    | _ -> failwith "Lines must be actions"
    in let events = buildEvents AutomatonEvent.empty events 
    in let () = checkAutomatonEvents events
    in if AutomatonEvent.mem state events then
        {state = state; events = events}
      else
        let () = Printf.eprintf "Error: Base state \"%s\" defined at line %d does not exist in automaton" state line in exit 1
  end

let rec runAutomaton automaton = function
| [] -> automaton.state
| event::tail ->
  let _, events = AutomatonEvent.find automaton.state automaton.events in
  let state = AutomatonEvent.find_opt event events in
  if state = None then 
    failwith "Check failed in automaton builder"
  else runAutomaton {automaton with state = Option.get state} tail

let runTest automaton = function
| Lexer.Action _ | Lexer.Init _ | Lexer.Node _ -> failwith "Test must be a test"
| Lexer.Test (line, events, expected) ->
  let result = runAutomaton automaton events in
  result = expected, line

let rec runTests automaton = function
| [] -> ()
| test::tail ->
  let pass, line = runTest automaton test in
  if pass then
    runTests automaton tail
  else
    failwith ("Test at line " ^ (string_of_int line) ^ " failed")