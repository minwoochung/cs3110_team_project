type t

type action = 
    | Roll
    | Reroll of bool list 
    | Score of Categories.t

type player_state = {
    name: string;
    scorecard: Scorecard.t;
}

type phase = 
    | Awaiting_roll
    | In_turn
    | Finished

type game_state = {
    players: player_state array;

    current_player: int;

    dice : int list option;

    rolls_used : int;

    phase : phase;
}

val create : int -> int -> t
val apply_action: t -> action -> t
val current_player : t -> int
val legal_actions : t -> action list
val is_finished : t -> bool
val get_state: t -> game_state
val final_scores : t -> int list