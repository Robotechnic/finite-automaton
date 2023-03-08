type automaton

val printAutomaton : automaton -> unit
(**
	Display the automaton in the console.

	@param [1] The automaton to print.
*)

val buildAutomaton : Lexer.line -> Lexer.line list -> automaton
(**
	Create a new automaton from the given list of action lines and an initial state.

	@param [1] The initial state of the automaton.
	@param [2] The list of action lines.
	@return a new automaton.
*)

val runAutomaton : automaton -> bool -> string list -> automaton
(**
	Run the automaton on the given list of tokens.

	@param [1] The automaton to run.
	@param [2] The list of tokens.
	@param [3] If true, it display all the intermediate states
	@return the automaton after running.
*)

val getAutomatonState : automaton -> string
(**
	Get the current state of the automaton.

	@param [1] The automaton.
	@return the current state of the automaton.
*)

val runTests : automaton -> bool -> Lexer.line list -> unit
(**
	Run the automaton on the given list of tests.
	It will exit with 1 if a test fails.

	@param [1] The automaton to run.
	@param [2] The list of tests.
	@param [3] If true, it display all the intermediate states
*)