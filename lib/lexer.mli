type token

type line =
  | Init of (int * int) * string (* Starting state of the automaton*)
  | Test of int * (string list) * string (* Test line of the automaton *)
  | MultiTest of int * line list (* MultiTest line of the automaton *)
  | Action of int * string * string * string (* Action of the automatons *)
  | Node of int * string (* A node is a way to define a terminal node *)

val parse : in_channel -> token list
(**
	Take a file name as input and return a list of tokens or raise an exception if the file is not found.
	
	@param [1] the file name
	@return the list of tokens in the file
*)

val printTokens : token list -> unit
(**
	Print the list of tokens to the standard output.
	
	@param [1] the list of tokens
*)

val lex : in_channel -> line * line list * line list
(**
	Take a list of tokens as input and return a list of lines or raise an exception if the list of tokens is not well-formed.
	
	@param [1] the list of tokens
	@return the starting state, the actions lines and the test lines
*)

val printLines : line list -> unit
(**
	Print the list of lines to the standard output.
	
	@param [1] the list of lines
*)