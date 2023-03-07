(lang dune 3.6)

(name automaton)

(generate_opam_files true)

(source
 (github robotechnic/automaton))

(authors "Robotechnic")

(maintainers "Robotechnic")

(package
 (name automaton)
 (synopsis "A programm to define finite automaton and test them")
 (description "This programm is a tool to define finite automaton using a simple syntax. It allow to test them and to generate a graphviz file to visualize and debug them.")
 (depends ocaml dune)
 (tags
  (automaton finite-state-machine graphviz)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
