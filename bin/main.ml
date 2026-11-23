open Team_project

let read_input prompt =
  print_string prompt;
  flush stdout;
  read_line ()

let rec choose_bot () =
  print_endline "Choose a bot opponent:";
  print_endline "  1. Random";
  print_endline "  2. Greedy";
  match String.lowercase_ascii (String.trim (read_input "> ")) with
  | "1" | "random" -> (module Random_bot : Bot_intf.BOT), "Random"
  | "2" | "greedy" -> (module Greedy_bot : Bot_intf.BOT), "Greedy"
  | _ ->
      print_endline "Please enter 1 (Random) or 2 (Greedy).";
      choose_bot ()

let apply game action =
  match Game.apply_action game action with
  | Ok next_game -> next_game
  | Error message -> failwith ("Unexpected illegal game action: " ^ message)

let legal_categories game =
  Game.legal_actions game
  |> List.filter_map (function
       | Game.Score category -> Some category
       | Game.Roll | Game.Reroll _ -> None)

type turn_choice = Keep of Dice.keep_mask | Score_now | Show_card

let parse_turn_input input =
  match String.lowercase_ascii (String.trim input) with
  | "score" -> Ok Score_now
  | "card" -> Ok Show_card
  | _ -> Result.map (fun keep -> Keep keep) (Terminal_ui.parse_keep_positions input)

(* Re-prompts on bad input without redrawing the screen, so the error
   message stays right above the prompt. *)
let rec ask parse prompt =
  match parse (read_input prompt) with
  | Ok value -> value
  | Error message ->
      print_endline ("  " ^ message ^ ". Try again.");
      ask parse prompt

let rec human_turn game =
  let state = Game.get_state game in
  match state.phase with
  | Game.Finished -> game
  | Game.Awaiting_roll -> human_turn (apply game Game.Roll)
  | Game.In_turn ->
      print_endline (Terminal_ui.render_game state);
      if state.rolls_used >= 3 then choose_score game state
      else (
        print_endline "Your move:";
        print_endline "  dice numbers (e.g. 1 3)  keep those dice, reroll the rest";
        print_endline "  none                     reroll all five dice";
        print_endline "  score                    stop rolling and pick a category";
        print_endline "  card                     view your scorecard";
        match ask parse_turn_input "> " with
        | Score_now -> choose_score game state
        | Show_card ->
            print_endline
              (Terminal_ui.render_scorecard
                 state.players.(state.current_player).Game.scorecard);
            human_turn game
        | Keep keep -> human_turn (apply game (Game.Reroll keep)))

and choose_score game state =
  let categories = legal_categories game in
  let card = state.players.(state.current_player).Game.scorecard in
  print_endline (Terminal_ui.render_score_menu card state.dice categories);
  let category =
    ask (Terminal_ui.parse_category categories) "Category number > "
  in
  apply game (Game.Score category)

let bot_turn (module Bot : Bot_intf.BOT) bot_name game bot_rng =
  let rec play game =
    let state = Game.get_state game in
    if state.phase = Game.Awaiting_roll then
      play (apply game Game.Roll)
    else if state.phase = Game.Finished then
      game
    else
      let dice =
        match state.dice with
        | Some dice -> dice
        | None -> failwith "In-turn game state has no dice"
      in
      let categories = legal_categories game in
      let observation : Bot_intf.observation =
        {
          dice;
          scorecard =
            state.players.(state.current_player).Game.scorecard;
          rolls_remaining = 3 - state.rolls_used;
          legal_categories = categories;
        }
      in
      if observation.rolls_remaining > 0 then (
        let keep = Bot.choose_keep bot_rng observation in
        print_endline
          (Terminal_ui.render_bot_roll bot_name state.rolls_used dice
             (Some keep));
        play (apply game (Game.Reroll keep)))
      else (
        let category = Bot.choose_category bot_rng observation in
        print_endline
          (Terminal_ui.render_bot_roll bot_name state.rolls_used dice None);
        print_endline
          (Terminal_ui.render_bot_score bot_name dice category);
        apply game (Game.Score category))
  in
  print_endline (Terminal_ui.render_turn_banner bot_name);
  play game

let print_results game =
  let state = Game.get_state game in
  let scores = Game.final_scores game in
  print_endline "\nFinal scores:";
  List.iter2
    (fun player score -> Printf.printf "  %s: %d\n" player.Game.name score)
    (Array.to_list state.players) scores;
  let highest = List.fold_left max min_int scores in
  let winners =
    List.filter_map
      (fun (player, score) ->
        if score = highest then Some player.Game.name else None)
      (List.combine (Array.to_list state.players) scores)
  in
  match winners with
  | [winner] -> Printf.printf "%s wins!\n" winner
  | _ -> Printf.printf "It's a tie between %s.\n" (String.concat ", " winners)

let play_game () =
  let bot, bot_name = choose_bot () in
  let seed = Random.bits () in
  let game = Game.create_named ["Human"; bot_name] seed in
  let bot_rng = Random.State.make [|seed; 1|] in
  let rec play game =
    if Game.is_finished game then game
    else
      let state = Game.get_state game in
      let next_game =
        if state.current_player = 0 then human_turn game
        else bot_turn bot bot_name game bot_rng
      in
      play next_game
  in
  play game |> print_results

let () =
  print_endline "Yahtzee: Human vs Bot";
  print_endline
    "Each turn: up to 3 rolls. Choose dice to keep by position, then score.";
  try play_game () with
  | End_of_file -> print_endline "\nInput ended; game stopped."