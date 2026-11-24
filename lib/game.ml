type action =
  | Roll
  | Reroll of Dice.keep_mask
  | Score of Categories.t

type player_state = {
  name : string;
  scorecard : Scorecard.t;
}

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

type t = {
  state : game_state;
  rng : Random.State.t;
}

(* Game creation *)

let create_named names seed =
  if names = [] then invalid_arg "Game.create_named needs at least one player"
  else if List.exists (fun name -> String.trim name = "") names then
    invalid_arg "Game.create_named requires player names to not be empty"
  else
    let players =
      List.map (fun name -> { name; scorecard = Scorecard.create () }) names
      |> Array.of_list
    in
    {
      state =
        {
          players;
          current_player = 0;
          dice = None;
          rolls_used = 0;
          phase = Awaiting_roll;
        };
      rng = Random.State.make [| seed |];
    }

let create num_players seed =
  if num_players <= 0 then
    invalid_arg "Game.create needs number of players to be positive"
  else
    let names =
      List.init num_players (fun i -> "Player " ^ string_of_int (i + 1))
    in
    create_named names seed

let current_player game = game.state.current_player
let get_state game = { game.state with players = Array.copy game.state.players }
let is_finished game = game.state.phase = Finished

let final_scores game =
  if not (is_finished game) then
    invalid_arg "Game.final_scores requires game to be finished"
  else
    Array.to_list
      (Array.map
         (fun player -> Scorecard.total_score player.scorecard)
         game.state.players)

(* Helper functions for scoring rules *)

let current_scorecard game =
  game.state.players.(game.state.current_player).scorecard

let upper_category value =
  match value with
  | 1 -> Categories.Ones
  | 2 -> Categories.Twos
  | 3 -> Categories.Threes
  | 4 -> Categories.Fours
  | 5 -> Categories.Fives
  | 6 -> Categories.Sixes
  | _ -> invalid_arg "Game.upper_category: invalid die value"

let matching_upper_category dice =
  match Dice.to_list dice with
  | value :: _ -> upper_category value
  | [] -> invalid_arg "Game.matching_upper_category: empty dice"

let is_repeat_yahtzee card dice =
  Scoring.is_yahtzee dice && Scorecard.get card Categories.Yahtzee <> None

let earns_yahtzee_bonus card dice =
  Scoring.is_yahtzee dice && Scorecard.get card Categories.Yahtzee = Some 50

let legal_scoring_categories card dice =
  let available = Scorecard.available_categories card in
  if not (is_repeat_yahtzee card dice) then available
  else
    let upper = matching_upper_category dice in
    if Scorecard.is_available card upper then [ upper ]
    else
      let lower =
        List.filter
          (fun category -> not (Categories.is_upper category))
          available
      in
      if lower <> [] then lower else List.filter Categories.is_upper available

let score_for_category card dice category =
  let joker_applies =
    is_repeat_yahtzee card dice
    && not (Scorecard.is_available card (matching_upper_category dice))
  in
  if joker_applies then
    match category with
    | Categories.Full_house -> 25
    | Categories.Small_straight -> 30
    | Categories.Large_straight -> 40
    | _ -> Scoring.score dice category
  else Scoring.score dice category

(* Legal actions *)

let all_keep_masks =
  List.init 32 (fun n -> List.init 5 (fun i -> n land (1 lsl i) <> 0))

let legal_actions game =
  let state = game.state in
  match state.phase with
  | Finished -> []
  | Awaiting_roll -> [ Roll ]
  | In_turn -> (
      match state.dice with
      | None -> []
      | Some dice ->
          let card = current_scorecard game in
          let scoring_actions =
            List.map
              (fun category -> Score category)
              (legal_scoring_categories card dice)
          in
          if state.rolls_used < 3 then
            let reroll_actions =
              List.map (fun mask -> Reroll mask) all_keep_masks
            in
            reroll_actions @ scoring_actions
          else scoring_actions)

(* Apply an action *)

let apply_action game action =
  let state = game.state in

  if not (List.mem action (legal_actions game)) then
    Error "Game.apply_action: illegal action"
  else
    let rng = Random.State.copy game.rng in
    match action with
    | Roll ->
        let dice = Dice.roll rng in
        let next_state =
          { state with dice = Some dice; rolls_used = 1; phase = In_turn }
        in
        Ok { state = next_state; rng }
    | Reroll keep -> (
        match state.dice with
        | None -> Error "Game.apply_action: no dice to reroll"
        | Some dice ->
            let new_dice = Dice.reroll rng dice keep in
            let next_state =
              {
                state with
                dice = Some new_dice;
                rolls_used = state.rolls_used + 1;
              }
            in
            Ok { state = next_state; rng })
    | Score category -> (
        match state.dice with
        | None -> Error "Game.apply_action: must roll before scoring"
        | Some dice -> (
            let card = current_scorecard game in
            let points = score_for_category card dice category in
            match Scorecard.record_score card category points with
            | Error message -> Error message
            | Ok updated_card ->
                let updated_card =
                  if earns_yahtzee_bonus card dice then
                    Scorecard.add_yahtzee_bonus updated_card
                  else updated_card
                in

                let players = Array.copy state.players in
                let index = state.current_player in
                let player = players.(index) in
                players.(index) <- { player with scorecard = updated_card };

                let finished =
                  Array.for_all
                    (fun player -> Scorecard.is_complete player.scorecard)
                    players
                in

                let next_player =
                  if finished then index
                  else (index + 1) mod Array.length players
                in

                let next_state =
                  {
                    players;
                    current_player = next_player;
                    dice = None;
                    rolls_used = 0;
                    phase = (if finished then Finished else Awaiting_roll);
                  }
                in

                Ok { state = next_state; rng }))
