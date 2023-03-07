module AutomatonEvent = Map.Make(String)

type automaton = {
  state : string;
  events : string AutomatonEvent.t AutomatonEvent.t
}

(**
  Check if all events defined in the automaton actions exists in the automaton
*)
let checkAutomatonEvents map =
  let rec checkEvents = function
  | [] -> ()
  | (event, _)::tails ->
    if not (AutomatonEvent.mem event map) then
      failwith ("Event " ^ event ^ " does not exist")
    else
      checkEvents tails
    in AutomatonEvent.iter (fun _ events -> checkEvents (AutomatonEvent.bindings events)) map

let buildAutomaton baseState events =
  match baseState with
  | Lexer.Action _ | Lexer.Test _ -> failwith "Base state must be a state"
  | Lexer.Init (_, state) -> begin
    let rec buildEvents map = function
    | [] -> map
    | Lexer.Action(_, from, if_, to_)::tails ->
      if AutomatonEvent.mem from map then
        let events = AutomatonEvent.find from map in
        buildEvents (AutomatonEvent.add from (AutomatonEvent.add if_ to_ events) map) tails
      else
        buildEvents (AutomatonEvent.add from (AutomatonEvent.singleton if_ to_) map) tails
    | _ -> failwith "Lines must be actions"
    in let events = buildEvents AutomatonEvent.empty events 
    in let () = checkAutomatonEvents events
    in if AutomatonEvent.mem state events then
        {state = state; events = events}
      else
        failwith "Base state does not exist"
  end

let rec runAutomaton automaton = function
| [] -> automaton.state
| event::tail ->
  let events = AutomatonEvent.find automaton.state automaton.events in
  let state = AutomatonEvent.find_opt event events in
  if state = None then failwith ("Event " ^ event ^ " is not applicable from state " ^ automaton.state)
  else runAutomaton {automaton with state = Option.get state} tail

let runTest automaton = function
| Lexer.Action _ | Lexer.Init _ -> failwith "Test must be a test"
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