let render_dice = function
  | None -> "Dice: not rolled yet"
  | Some dice ->
      let values = Dice.to_list dice in
      let positions =
        String.concat "  "
          (List.mapi (fun i _ -> Printf.sprintf "[%d]" (i + 1)) values)
      in
      let faces =
        String.concat "  " (List.map (fun v -> Printf.sprintf " %d " v) values)
      in
      positions ^ "\n" ^ faces

let render_scorecard card =
  let rows =
    List.map
      (fun category ->
        let score =
          match Scorecard.get card category with
          | None -> "--"
          | Some points -> string_of_int points
        in
        Printf.sprintf "  %-20s %s" (Categories.to_string category) score)
      Categories.all
  in
  let totals =
    [
      Printf.sprintf "  %-20s %d" "Upper subtotal"
        (Scorecard.upper_subtotal card);
      Printf.sprintf "  %-20s %d" "Upper bonus" (Scorecard.upper_bonus card);
      Printf.sprintf "  %-20s %d" "Yahtzee bonus" (Scorecard.yahtzee_bonus card);
      Printf.sprintf "  %-20s %d" "Total" (Scorecard.total_score card);
    ]
  in
  String.concat "\n" (("Scorecard:" :: rows) @ totals)

let render_game (state : Game.game_state) =
  let current = state.players.(state.current_player) in
  let scores =
    Array.to_list
      (Array.mapi
         (fun index player ->
           Printf.sprintf "%s%s %d"
             (if index = state.current_player then "> " else "")
             player.Game.name
             (Scorecard.total_score player.Game.scorecard))
         state.players)
    |> String.concat "   "
  in
  let phase =
    match state.phase with
    | Game.Awaiting_roll -> "Awaiting roll"
    | Game.In_turn -> "In turn"
    | Game.Finished -> "Finished"
  in
  let rolls_remaining =
    match state.phase with
    | Game.Finished -> 0
    | Game.Awaiting_roll -> 3
    | Game.In_turn -> 3 - state.rolls_used
  in
  let header =
    [
      "";
      Printf.sprintf "Turn: %s (%s)   Rolls remaining: %d" current.Game.name
        phase rolls_remaining;
      render_dice state.dice;
      "Scores: " ^ scores;
    ]
  in
  (* The full scorecard is only shown when the player must score. *)
  let scorecard =
    if state.phase = Game.In_turn && rolls_remaining = 0 then
      [ ""; render_scorecard current.Game.scorecard ]
    else []
  in
  String.concat "\n" (header @ scorecard)

let render_score_menu card dice categories =
  let points category =
    match dice with
    | Some d -> Printf.sprintf "%3d" (Scoring.score d category)
    | None -> "  -"
  in
  let rows =
    List.mapi
      (fun index category ->
        Printf.sprintf "  %2d. %-18s %s" (index + 1)
          (Categories.to_string category)
          (points category))
      categories
  in
  String.concat "\n"
    (("Choose a category (points if scored now):" :: rows)
    @ [ Printf.sprintf "Total so far: %d" (Scorecard.total_score card) ])

let render_turn_banner name = Printf.sprintf "\n=== %s's turn ===" name

let render_bot_roll name roll_number dice keep =
  let header = Printf.sprintf "%s, roll %d of 3:" name roll_number in
  let keep_lines =
    match keep with
    | None -> []
    | Some mask ->
        let marks =
          String.concat "  "
            (List.map (fun kept -> if kept then " ^ " else "   ") mask)
        in
        let kept_positions =
          List.mapi
            (fun index kept -> if kept then Some (index + 1) else None)
            mask
          |> List.filter_map Fun.id
        in
        let summary =
          match kept_positions with
          | [] -> Printf.sprintf "%s rerolls all dice." name
          | positions when List.length positions = List.length mask ->
              Printf.sprintf "%s keeps all dice." name
          | positions ->
              Printf.sprintf "%s keeps dice %s and rerolls the rest." name
                (String.concat ", " (List.map string_of_int positions))
        in
        [ marks; summary ]
  in
  String.concat "\n" (header :: render_dice (Some dice) :: keep_lines)

let render_bot_score name dice category =
  Printf.sprintf "%s scores %d in %s." name
    (Scoring.score dice category)
    (Categories.to_string category)

let parse_keep_positions input =
  let trimmed = String.trim input |> String.lowercase_ascii in
  if trimmed = "all" then Ok [ true; true; true; true; true ]
  else if trimmed = "none" then Ok [ false; false; false; false; false ]
  else if trimmed = "" then Error "Enter die positions, all, or none"
  else
    let tokens =
      String.split_on_char ',' trimmed
      |> List.map String.trim
      |> List.concat_map (String.split_on_char ' ')
      |> List.filter (fun token -> token <> "")
    in
    let rec parse_tokens positions = function
      | [] -> Ok (List.init 5 (fun index -> List.mem (index + 1) positions))
      | token :: rest -> (
          match int_of_string_opt token with
          | None -> Error ("Invalid die position: " ^ token)
          | Some position when position < 1 || position > 5 ->
              Error "Die positions must be between 1 and 5"
          | Some position when List.mem position positions ->
              Error ("Die position entered more than once: " ^ token)
          | Some position -> parse_tokens (position :: positions) rest)
    in
    parse_tokens [] tokens

let parse_category categories input =
  let trimmed = String.trim input in
  match int_of_string_opt trimmed with
  | Some index when index >= 1 && index <= List.length categories ->
      Ok (List.nth categories (index - 1))
  | Some _ -> Error "Category number is out of range"
  | None -> (
      match Categories.of_string trimmed with
      | Some category when List.mem category categories -> Ok category
      | _ -> Error "Enter a listed category name or number")
