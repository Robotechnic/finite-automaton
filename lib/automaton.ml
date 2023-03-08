module AutomatonEvent = Map.Make(String)

type automaton = {
  state : string;
  events : (int * (int * string) AutomatonEvent.t) AutomatonEvent.t
}

let getAutomatonState automaton = automaton.state

let printAutomaton automaton = 
  let () = Printf.printf "Base state: %s\n" automaton.state in
  AutomatonEvent.iter (fun key (line, events) ->
    let () = Printf.printf "State \"%s\" firstly defined at line %d:\n" key line in
    AutomatonEvent.iter (fun key (eventLine, value) ->
      let () = Printf.printf "\tEvent defined at line %d : %s -> %s\n" eventLine key value in
      ()
    ) events
  ) automaton.events

(**
  Check if all events defined in the automaton actions exists in the automaton
*)
let checkAutomatonEvents map =
  let rec checkEvents = function
  | [] -> ()
  | (_, (nodeLine, endNode))::tails ->
    if not (AutomatonEvent.mem endNode map) then
      let () = Printf.eprintf "Error: End node \"%s\" defined at line %d does not exist in automaton\n" endNode nodeLine in exit 1
    else
      checkEvents tails
    in AutomatonEvent.iter (fun _ (_, events) -> checkEvents (AutomatonEvent.bindings events)) map

let buildAutomaton baseState events =
  match baseState with
  | Lexer.Action _ | Lexer.Test _ | Lexer.Node _  | Lexer.MultiTest _ -> failwith "Base state must be a state"
  | Lexer.Init ((line, _), state) -> begin
    let rec buildEvents map = function
    | [] -> map
    | Lexer.Node(line, literal)::tails -> 
      if AutomatonEvent.mem literal map then
        buildEvents map tails
      else
        buildEvents (AutomatonEvent.add literal (line, AutomatonEvent.empty) map) tails
    | Lexer.Action(line, literal, "_", to_)::tails ->
      if AutomatonEvent.mem literal map then
        let () = Printf.printf "Warning: Wilcard action at line %d will overwrite previous actions\n" line in
        buildEvents (AutomatonEvent.add literal (line, AutomatonEvent.singleton "_" (line, to_)) map) tails
      else
        buildEvents (AutomatonEvent.add literal (line, AutomatonEvent.singleton "_" (line, to_)) map) tails
    | Lexer.Action(actionLine, from, if_, to_)::tails ->
      let events = AutomatonEvent.find_opt from map in
      if events <> None then
        let line, events = Option.get events in
        if AutomatonEvent.mem "_" events then
          let () = Printf.printf "Warning : Action at line %d won't be executed because of the wildcard action defined at line %d\n" actionLine line in
          buildEvents map tails
        else
          buildEvents (AutomatonEvent.add from (line, (AutomatonEvent.add if_ (actionLine, to_) events)) map) tails
      else
        buildEvents (AutomatonEvent.add from (actionLine, (AutomatonEvent.singleton if_ (actionLine, to_))) map) tails
    | _ -> assert false
    in let events = buildEvents AutomatonEvent.empty events
    in let () = checkAutomatonEvents events
    in if AutomatonEvent.mem state events then
        {state = state; events = events}
      else
        let () = Printf.eprintf "Error: Base state \"%s\" defined at line %d does not exist in automaton\n" state line in exit 1
  end

let rec runAutomaton automaton substeps = function
| [] -> automaton
| event::tail as actions ->
  let _, events = AutomatonEvent.find automaton.state automaton.events in
  let wildcard = AutomatonEvent.find_opt "_" events in
  if wildcard <> None then
    runAutomaton {automaton with state = snd (Option.get wildcard)} substeps actions
  else
    let state = AutomatonEvent.find_opt event events in
    if state = None then 
      let () = Printf.eprintf "Error: Event \"%s\" is not defined for state \"%s\"\n" event automaton.state in exit 1
    else
      let () = if substeps then print_endline automaton.state
      in runAutomaton {automaton with state = snd (Option.get state)} substeps tail

let runTest automaton substeps = function
| Lexer.Action _ | Lexer.Init _ | Lexer.Node _ -> assert false
| Lexer.Test (line, (events, expected)) ->
  let result = runAutomaton automaton substeps events in
  result.state = expected, line
| Lexer.MultiTest (line, tests) -> 
  let rec runMultiTest automaton = function
  | [] -> true, line
  | (testLine, (events, expected))::tail ->
    let result = runAutomaton automaton substeps events in
    if result.state = expected then
      runMultiTest result tail
    else
      false, testLine
  in runMultiTest automaton tests

let rec runTests automaton substeps = function
| [] -> ()
| test::tail ->
  let pass, line = runTest automaton substeps test in
  if pass then
    runTests automaton substeps tail
  else
    let () = Printf.eprintf "Error: Test at line %d failed\n" line in exit 1