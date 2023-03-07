val export : string -> Lexer.line -> Lexer.line list -> unit
(**
	Export the automaton described by the given lines into graphviz format.

	@param [1] the name of the file to export to
	@param [2] the lines describing the automaton
*)