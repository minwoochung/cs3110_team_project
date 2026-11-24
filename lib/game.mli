(** The game engine for Yahtzee.

    This module manages game creation, player turns, dice rolls, scoring
    actions, and game progression. The rules of the game are enforced by this
    module rather than by bots or the UI. *)

type t
(** The abstract type representing a Yahtzee game.

    A game contains its current state and the random generator used for rolling
    dice. *)

(** The actions that a player can perform during a game.

    [Roll] rolls all five dice at the beginning of a turn.

    [Reroll keep] rerolls the dice whose corresponding entries in [keep] are
    [false]. Dice marked [true] are kept.

    [Score category] records a score in [category] and ends the current player's
    turn. *)
type action =
  | Roll
  | Reroll of Dice.keep_mask
  | Score of Categories.t

type player_state = {
  name : string;
  scorecard : Scorecard.t;
}
(** The state of an individual player. *)

(** The phases of a Yahtzee game.

    [Awaiting_roll] means the current player has not rolled.

    [In_turn] means the player has rolled and may reroll or select a scoring
    category.

    [Finished] means all players have completed their scorecards. *)
type phase =
  | Awaiting_roll
  | In_turn
  | Finished

type game_state = {
  players : player_state array;
  current_player : int;
  dice : Dice.t option;
  rolls_used : int;
  phase : phase;
}
(** A snapshot of the current game state.

    [players] contains the players in turn order.

    [current_player] is the zero-based index of the player whose turn it is.

    [dice] is [None] before the first roll of a turn and [Some dice] after
    rolling.

    [rolls_used] is the number of rolls made during the current turn, between
    [0] and [3].

    [phase] is the current phase of the game. *)

val create : int -> int -> t
(** [create num_players seed] is a new game containing [num_players] players
    named "Player 1", "Player 2", and so on.

    Each player begins with an empty scorecard. The game begins in
    [Awaiting_roll], and its random generator is initialized using [seed].

    Requires: [num_players] > 0.

    Raises: [Invalid_argument] if [num_players] is not positive. *)

val create_named : string list -> int -> t
(** [create_named names seed] is a new game whose players have the names in
    [names], in the given order.

    Each player begins with an empty scorecard. The random generator is
    initialized using [seed].

    Requires: [names] is nonempty and contains no empty player names.

    Raises: [Invalid_argument] if the precondition is violated. *)

val legal_actions : t -> action list
(** [legal_actions game] is the list of legal actions available in [game].

    In [Awaiting_roll], the only legal action is [Roll].

    In [In_turn], the player may score in a legally available category. If fewer
    than three rolls have been used, the player may also reroll dice using a
    valid keep mask.

    Legal scoring actions follow category availability and the applicable
    Yahtzee rules.

    In [Finished], the result is [[]]. *)

val apply_action : t -> action -> (t, string) result
(** [apply_action game action] is [Ok next_game] if [action] is legal in [game],
    where [next_game] is the state resulting from performing [action].

    Rolling and rerolling use the game's seeded random generator. A scoring
    action updates the current player's scorecard and advances the turn.

    The original [game], including its random generator, is not modified.

    The result is [Error message] if [action] is illegal, including an invalid
    keep mask, an unavailable scoring category, or an action attempted in the
    wrong phase. *)

val current_player : t -> int
(** [current_player game] is the zero-based index of the player whose turn it
    is. *)

val get_state : t -> game_state
(** [get_state game] is a snapshot of the current game state.

    Modifying the returned [players] array does not change the internal state of
    [game]. *)

val is_finished : t -> bool
(** [is_finished game] is [true] if all players have completed their thirteen
    scoring categories, and [false] otherwise. *)

val final_scores : t -> int list
(** [final_scores game] is the list of final total scores, in player order.

    Each total includes category scores, the upper-section bonus, and any
    additional Yahtzee bonuses.

    Requires: [is_finished game] is [true].

    Raises: [Invalid_argument] if [game] has not finished. *)
