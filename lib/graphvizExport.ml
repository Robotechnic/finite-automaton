let export file base actions =
  let () = Printf.fprintf file "digraph Automaton {" in
  let () = match base with
  | Lexer.Init(_, from) -> Printf.fprintf file "%s [shape=doublecircle,color=red];" from
  | _ -> failwith "No base state"
  in let rec loop = function
    | [] -> ()
    | Lexer.Action(_, from, if_, to_) :: rest ->
      let () = if if_ = "_" then
        Printf.fprintf file "%s -> %s [style=dashed];" from to_
      else
         Printf.fprintf file "%s -> %s [label=\"%s\"];" from to_ if_
      in loop rest
    | _ :: rest -> loop rest
  in let () = loop actions in
  Printf.fprintf file "}"