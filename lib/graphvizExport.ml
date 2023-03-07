let export fileName lines =
  let file = open_out fileName in
  let () = Printf.fprintf file "digraph Automaton {" in
  let rec loop = function
    | [] -> ()
    | Lexer.Action(_, from, if_, to_) :: rest ->
      let () = Printf.fprintf file "%s -> %s [label=\"%s\"];" from to_ if_ in
      loop rest
    | Lexer.Init (_, from) :: rest ->
      let () = Printf.fprintf file "%s [shape=doublecircle,color=red];" from in
      loop rest
    | _ :: rest -> loop rest
  in let () = loop lines in
  let () = Printf.fprintf file "}" in
  close_out file