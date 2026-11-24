(** Simulation and evaluation of Yahtzee bots.

    This module runs complete Yahtzee games using bot strategies and collects
    results from repeated games.

    Each simulation uses an explicit random seed to make its results
    reproducible. *)

type game_result = {
  scores : int list;
  winner : int option;
}
(** The result of a completed game.

    [scores] contains the final total score of each player in player order.

    [winner] is [Some i] if player [i] has the unique highest score, or [None]
    if the highest score is tied. *)

type simulation_result = {
  games_played : int;
  average_scores : float list;
  wins : int list;
  ties : int;
}
(** Statistics collected from repeated games.

    [games_played] is the number of completed games.

    [average_scores] contains the mean final score of each player, in player
    order.

    [wins] contains the number of games each player wins outright, excluding
    ties.

    [ties] is the number of games in which multiple players share the highest
    score. *)

module type BOT = Bot_intf.BOT
(** The interface for a bot that can participate in a simulation. *)

(** A simulator for a fixed collection of bot strategies.

    [Make] creates a simulator in which the bots supplied through [BOTS] compete
    against one another. *)
module type BOTS = sig
  val bots : (module BOT) list
  (** [bots] is a nonempty list of bot modules.

      The order of the list determines the player order. *)
end

(** [Make (B)] is a simulator using the bots in [B.bots].

    The number and order of players are determined by [B.bots]. *)
module Make (B : BOTS) : sig
  val run_game : int -> game_result
  (** [run_game seed] is the result of one complete game played by the
      configured bots.

      The game is initialized using [seed]. Each bot makes decisions using
      observations derived from the current game state.

      Every bot uses all three rolls in each turn before selecting a scoring
      category.

      Bot random generators are derived deterministically from [seed] and are
      separate from the game's dice random generator.

      Requires: [B.bots] is nonempty and each bot follows the [BOT] interface
      contracts. *)

  val run_many : int -> int -> simulation_result
  (** [run_many n seed] is the summary of [n] completed games played by the
      configured bots.

      Game [i] uses a deterministic seed derived from [seed] and [i], so
      repeated calls with the same arguments produce the same results.

      [average_scores] contains the arithmetic mean of each player's final
      scores across all [n] games.

      Requires: [n] > 0 and [B.bots] is nonempty.

      Raises: [Invalid_argument] if [n] is not positive. *)
end
