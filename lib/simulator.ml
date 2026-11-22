
(** Simulation and evaluation of Yahtzee bots. *)

(** The result of one completed game. *)
type game_result = {
  scores : int list;
  winner : int option;
}

(** Statistics from multiple completed games. *)
type simulation_result = {
  games_played : int;
  average_scores : float list;
  wins : int list;
  ties : int;
}

(** The interface for a complete bot. *)
module type BOT = Bot_intf.BOT

(** A collection of bots participating in a simulation. *)
module type BOTS = sig
  val bots : (module BOT) list
end

(** A simulator using the supplied bot strategies. *)
module Make (B : BOTS) = struct
  let bots = Array.of_list B.bots
  let num_players = Array.length bots

  (** [apply game action] performs [action] and returns
      the updated game.

      Raises: [Failure] if the action is illegal. *)
  let apply game action =
    match Game.apply_action game action with
    | Ok next_game -> next_game
    | Error message -> failwith ("Simulator: " ^ message)

  (** [legal_categories game] is the list of currently
      legal scoring categories. *)
  let legal_categories game =
    Game.legal_actions game
    |> List.filter_map (function
         | Game.Score category -> Some category
         | _ -> None)

  (** [make_observation game] is the observation for the
      current player.

      Requires: The game is in [In_turn].

      Raises: [Failure] if no dice are available. *)
  let make_observation game =
    let state = Game.get_state game in
    match state.dice with
    | None -> failwith "Simulator: dice are unavailable"
    | Some dice ->
        let player = state.players.(state.current_player) in
        {
          Bot_intf.dice = dice;
          scorecard = player.scorecard;
          rolls_remaining = 3 - state.rolls_used;
          legal_categories = legal_categories game;
        }

  (** [find_winner scores] is [Some i] if player [i]
      has the unique highest score, or [None] if the
      highest score is tied.

      Requires: [scores] is nonempty. *)
  let find_winner scores =
    let highest = List.fold_left max min_int scores in
    let winners =
      List.mapi
        (fun index score -> (index, score))
        scores
      |> List.filter (fun (_, score) -> score = highest)
    in
    match winners with
    | [ (index, _) ] -> Some index
    | _ -> None

  (** [run_game seed] runs one complete Yahtzee game
      using the configured bots and [seed].

      Every bot uses all three rolls in each turn.
      Bot random generators are separate from the
      game random generator. *)
  let run_game seed =
    if num_players = 0 then
      invalid_arg "Simulator.run_game: no bots";

    let rngs =
      Array.init num_players (fun i ->
        Random.State.make [| seed; i; 7919 |])
    in

    let initial_game = Game.create num_players seed in

    let rec play game =
      if Game.is_finished game then
        let scores = Game.final_scores game in
        {
          scores;
          winner = find_winner scores;
        }
      else
        let state = Game.get_state game in
        let player_index = state.current_player in

        let module Bot =
          (val bots.(player_index) : BOT)
        in

        let rng = rngs.(player_index) in

        match state.phase with
        | Game.Awaiting_roll ->
            let next_game = apply game Game.Roll in
            play next_game

        | Game.In_turn ->
            let obs = make_observation game in

            if obs.rolls_remaining > 0 then
              let keep = Bot.choose_keep rng obs in
              let next_game =
                apply game (Game.Reroll keep)
              in
              play next_game
            else
              let category =
                Bot.choose_category rng obs
              in
              let next_game =
                apply game (Game.Score category)
              in
              play next_game

        | Game.Finished ->
            failwith "Simulator: inconsistent game state"
    in
    play initial_game

  (** [run_many n seed] runs [n] games and returns
      the average score, number of wins, and number
      of ties.

      Game [i] uses seed [seed + i].

      Requires: [n] > 0 and at least one bot exists.

      Raises: [Invalid_argument] if a precondition
      is violated. *)
  let run_many n seed =
    if n <= 0 then
      invalid_arg "Simulator.run_many: n must be positive";

    if num_players = 0 then
      invalid_arg "Simulator.run_many: no bots";

    let total_scores = Array.make num_players 0.0 in
    let wins = Array.make num_players 0 in
    let ties = ref 0 in

    for i = 0 to n - 1 do
      let result = run_game (seed + i) in

      List.iteri
        (fun index score ->
          total_scores.(index) <-
            total_scores.(index) +. float_of_int score)
        result.scores;

      match result.winner with
      | Some index ->
          wins.(index) <- wins.(index) + 1
      | None ->
          incr ties
    done;

    let average_scores =
      Array.to_list
        (Array.map
           (fun total -> total /. float_of_int n)
           total_scores)
    in

    {
      games_played = n;
      average_scores;
      wins = Array.to_list wins;
      ties = !ties;
    }
end
