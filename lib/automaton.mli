type automaton

val buildAutomaton : Lexer.line -> Lexer.line list -> automaton

val runAutomaton : automaton -> string list -> string

val runTests : automaton -> Lexer.line list -> unit