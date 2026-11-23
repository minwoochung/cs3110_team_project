open OUnit2
open Team_project

let contains text fragment =
  let text_length = String.length text in
  let fragment_length = String.length fragment in
  let rec search index =
    index + fragment_length <= text_length
    && (String.sub text index fragment_length = fragment
       || search (index + 1))
  in
  search 0

let test_keep_positions _ =
  assert_equal (Ok [true; false; true; false; false])
    (Terminal_ui.parse_keep_positions "1, 3");
  assert_equal (Ok [true; true; true; true; true])
    (Terminal_ui.parse_keep_positions "all");
  assert_equal (Ok [false; false; false; false; false])
    (Terminal_ui.parse_keep_positions "none")

let test_invalid_keep_positions _ =
  assert_bool "Out-of-range position should be rejected"
    (Result.is_error (Terminal_ui.parse_keep_positions "6"));
  assert_bool "Duplicate position should be rejected"
    (Result.is_error (Terminal_ui.parse_keep_positions "2, 2"));
  assert_bool "Non-numeric input should be rejected"
    (Result.is_error (Terminal_ui.parse_keep_positions "one"));
  assert_bool "Empty input should be rejected"
    (Result.is_error (Terminal_ui.parse_keep_positions ""))

let test_parse_category _ =
  let categories = [Categories.Ones; Categories.Chance] in
  assert_equal (Ok Categories.Chance)
    (Terminal_ui.parse_category categories "2");
  assert_equal (Ok Categories.Ones)
    (Terminal_ui.parse_category categories " ones ");
  assert_bool "Unavailable category should be rejected"
    (Result.is_error
       (Terminal_ui.parse_category categories "Yahtzee"))

let test_render_scorecard _ =
  let rendered = Terminal_ui.render_scorecard (Scorecard.create ()) in
  assert_bool "Should show categories"
    (contains rendered "Yahtzee");
  assert_bool "Should show empty category markers"
    (contains rendered "--")

let test_render_dice _ =
  let rendered =
    Terminal_ui.render_dice (Some (Dice.of_list [1; 2; 3; 4; 5]))
  in
  assert_bool "Should show die positions"
    (contains rendered "[1]" && contains rendered "[5]");
  assert_bool "Should show die values"
    (contains rendered " 1    2    3    4    5 ")

let test_render_game _ =
  let game = Game.create_named ["Human"; "Random"] 42 in
  let rendered = Terminal_ui.render_game (Game.get_state game) in
  assert_bool "Should identify the current player"
    (contains rendered "Turn: Human");
  assert_bool "Should show all rolls before a turn"
    (contains rendered "Rolls remaining: 3")

let test_render_score_menu _ =
  let dice = Some (Dice.of_list [1; 1; 1; 2; 3]) in
  let rendered =
    Terminal_ui.render_score_menu (Scorecard.create ()) dice
      [Categories.Ones; Categories.Chance]
  in
  assert_bool "Should number the categories"
    (contains rendered "1. Ones" && contains rendered "2. Chance");
  assert_bool "Should show the total" (contains rendered "Total so far: 0")

let test_render_bot_roll _ =
  let dice = Dice.of_list [4; 4; 2; 6; 1] in
  let rendered =
    Terminal_ui.render_bot_roll "Greedy" 1 dice
      (Some [true; true; false; false; false])
  in
  assert_bool "Should name the roll" (contains rendered "Greedy, roll 1 of 3");
  assert_bool "Should say which dice are kept"
    (contains rendered "keeps dice 1, 2 and rerolls the rest");
  let final = Terminal_ui.render_bot_roll "Greedy" 3 dice None in
  assert_bool "Final roll has no keep summary"
    (not (contains final "keeps"))

let test_render_bot_score _ =
  let dice = Dice.of_list [2; 2; 3; 3; 3] in
  assert_equal "Greedy scores 25 in Full House."
    (Terminal_ui.render_bot_score "Greedy" dice Categories.Full_house)

let suite =
  "Terminal UI Tests"
  >::: [
         "keep_positions" >:: test_keep_positions;
         "invalid_keep_positions" >:: test_invalid_keep_positions;
         "parse_category" >:: test_parse_category;
         "render_scorecard" >:: test_render_scorecard;
         "render_dice" >:: test_render_dice;
         "render_game" >:: test_render_game;
         "render_score_menu" >:: test_render_score_menu;
         "render_bot_roll" >:: test_render_bot_roll;
         "render_bot_score" >:: test_render_bot_score;
       ]

let () = run_test_tt_main suite