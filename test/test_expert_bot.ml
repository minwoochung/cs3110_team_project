open OUnit2
open Team_project

let rng () = Random.State.make [| 42 |]

(** [card_with entries] is a scorecard with each
    [(category, score)] in [entries] already recorded. *)
let card_with entries =
  List.fold_left
    (fun card (category, score) ->
      match Scorecard.record_score card category score with
      | Ok card -> card
      | Error msg -> failwith msg)
    (Scorecard.create ()) entries

(** [make_obs ?card values] is an observation with dice
    [values], two rerolls left, and every open category on
    [card] legal. *)
let make_obs ?(card = Scorecard.create ()) values : Bot_intf.observation =
  {
    dice = Dice.of_list values;
    scorecard = card;
    rolls_remaining = 2;
    legal_categories = Scorecard.available_categories card;
  }

let keep ?card values = Expert_bot.choose_keep (rng ()) (make_obs ?card values)

let pick ?card values =
  Expert_bot.choose_category (rng ()) (make_obs ?card values)

let pp_mask m =
  "[" ^ String.concat "; " (List.map string_of_bool m) ^ "]"

let pp_cat = Categories.to_string

let keep_test name ?card values expected =
  name >:: fun _ ->
  assert_equal ~printer:pp_mask expected (keep ?card values)

let pick_test name ?card values expected =
  name >:: fun _ ->
  assert_equal ~printer:pp_cat expected (pick ?card values)

let t = true
let f = false

(* ---------- helpers ---------- *)

let helper_tests =
  [
    ( "par upper is three of a face" >:: fun _ ->
      assert_equal 18 (Expert_bot.par Categories.Sixes);
      assert_equal 3 (Expert_bot.par Categories.Ones) );
    ( "upper pars add up to the bonus line" >:: fun _ ->
      let total =
        List.fold_left
          (fun acc c ->
            if Categories.is_upper c then acc + Expert_bot.par c else acc)
          0 Categories.all
      in
      assert_equal 63 total );
    ( "longest run finds a small straight" >:: fun _ ->
      assert_equal (1, 4) (Expert_bot.longest_run (Dice.of_list [ 3; 1; 4; 2; 6 ]))
    );
    ( "longest run of identical dice is 1" >:: fun _ ->
      assert_equal (5, 1) (Expert_bot.longest_run (Dice.of_list [ 5; 5; 5; 5; 5 ]))
    );
    ( "longest run tie goes to higher values" >:: fun _ ->
      assert_equal (5, 2) (Expert_bot.longest_run (Dice.of_list [ 1; 2; 5; 6; 1 ]))
    );
    ( "target is the most common value" >:: fun _ ->
      assert_equal 3
        (Expert_bot.target_value (Scorecard.create ())
           (Dice.of_list [ 3; 6; 3; 1; 3 ])) );
    ( "target tie prefers higher value" >:: fun _ ->
      assert_equal 6
        (Expert_bot.target_value (Scorecard.create ())
           (Dice.of_list [ 2; 2; 6; 6; 4 ])) );
    ( "target tie prefers an open upper category" >:: fun _ ->
      let card = card_with [ (Categories.Sixes, 18) ] in
      assert_equal 2
        (Expert_bot.target_value card (Dice.of_list [ 2; 2; 6; 6; 4 ])) );
    ( "bonus live on a new card" >:: fun _ ->
      assert_bool "live" (Expert_bot.bonus_live (Scorecard.create ())) );
    ( "bonus not live once earned" >:: fun _ ->
      let card =
        card_with
          Categories.
            [ (Fours, 16); (Fives, 20); (Sixes, 30) ]
      in
      assert_bool "earned" (not (Expert_bot.bonus_live card)) );
    ( "bonus not live once unreachable" >:: fun _ ->
      let card =
        card_with Categories.[ (Fives, 0); (Sixes, 0) ]
      in
      assert_bool "unreachable" (not (Expert_bot.bonus_live card)) );
    ( "utility adds bonus push at par" >:: fun _ ->
      let dice = Dice.of_list [ 6; 6; 6; 1; 2 ] in
      assert_equal
        (18 - 18 + Expert_bot.bonus_push)
        (Expert_bot.utility (Scorecard.create ()) dice Categories.Sixes) );
    ( "utility below par has no push" >:: fun _ ->
      let dice = Dice.of_list [ 6; 6; 3; 1; 2 ] in
      assert_equal (-6)
        (Expert_bot.utility (Scorecard.create ()) dice Categories.Sixes) );
  ]

(* ---------- reroll rules ---------- *)

let keep_tests =
  [
    keep_test "keeps a yahtzee" [ 4; 4; 4; 4; 4 ] [ t; t; t; t; t ];
    keep_test "keeps a large straight" [ 2; 3; 4; 5; 6 ] [ t; t; t; t; t ];
    keep_test "keeps a full house" [ 3; 5; 3; 5; 3 ] [ t; t; t; t; t ];
    keep_test "full house used: collects the triple"
      ~card:(card_with [ (Categories.Full_house, 25) ])
      [ 3; 5; 3; 5; 3 ] [ t; f; t; f; t ];
    keep_test "chases large straight from four in a row" [ 1; 2; 3; 4; 1 ]
      [ t; t; t; t; f ];
    keep_test "keeps small straight when large is used"
      ~card:(card_with [ (Categories.Large_straight, 40) ])
      [ 1; 2; 3; 4; 1 ] [ t; t; t; t; t ];
    keep_test "chases 3-4-5-6 toward a large straight" [ 1; 3; 4; 5; 6 ]
      [ f; t; t; t; t ];
    keep_test "chases three in a row with no pairs" [ 1; 2; 3; 5; 6 ]
      [ t; t; t; f; f ];
    keep_test "straights used: no straight chase"
      ~card:
        (card_with
           [ (Categories.Small_straight, 30); (Categories.Large_straight, 40) ])
      [ 1; 2; 3; 4; 6 ] [ f; f; f; f; t ];
    keep_test "keeps two pairs for full house" [ 2; 5; 2; 5; 6 ]
      [ t; t; t; t; f ];
    keep_test "collects the most common value" [ 6; 1; 6; 3; 6 ]
      [ t; f; t; f; t ];
    keep_test "pair with three in a row prefers the pair" [ 2; 3; 4; 4; 6 ]
      [ f; f; t; t; f ];
  ]

(* ---------- scoring rules ---------- *)

let pick_tests =
  [
    pick_test "scores a yahtzee" [ 5; 5; 5; 5; 5 ] Categories.Yahtzee;
    pick_test "scores a large straight" [ 1; 2; 3; 4; 5 ]
      Categories.Large_straight;
    pick_test "three sixes go to Sixes for the bonus" [ 6; 6; 6; 4; 5 ]
      Categories.Sixes;
    pick_test "three sixes go to 3-of-a-kind once bonus is earned"
      ~card:
        (card_with
           Categories.[ (Twos, 6); (Threes, 15); (Fours, 20); (Fives, 25) ])
      [ 6; 6; 6; 4; 5 ] Categories.Three_of_a_kind;
    pick_test "bad roll is sacrificed in Ones" [ 1; 2; 4; 6; 6 ]
      Categories.Ones;
    pick_test "full house when its triple's upper box is used"
      ~card:(card_with [ (Categories.Threes, 9) ])
      [ 2; 2; 3; 3; 3 ] Categories.Full_house;
    pick_test "triple at par prefers upper box over full house"
      [ 2; 2; 3; 3; 3 ] Categories.Threes;
    pick_test "only legal category is chosen"
      ~card:
        (card_with
           (List.filter_map
              (fun c -> if c = Categories.Chance then None else Some (c, 0))
              Categories.all))
      [ 1; 1; 1; 1; 1 ] Categories.Chance;
    ( "empty legal list raises" >:: fun _ ->
      let obs = { (make_obs [ 1; 2; 3; 4; 5 ]) with legal_categories = [] } in
      assert_raises
        (Invalid_argument "Expert_bot.choose_category: no legal categories")
        (fun () -> Expert_bot.choose_category (rng ()) obs) );
  ]

(* ---------- full games ---------- *)

module Expert_vs_greedy = Simulator.Make (struct
  let bots =
    [ (module Expert_bot : Bot_intf.BOT); (module Greedy_bot : Bot_intf.BOT) ]
end)

module Expert_vs_random = Simulator.Make (struct
  let bots =
    [ (module Expert_bot : Bot_intf.BOT); (module Random_bot : Bot_intf.BOT) ]
end)

let avg r i = List.nth r.Simulator.average_scores i

let game_tests =
  [
    ( "plays complete games with legal moves" >:: fun _ ->
      let r = Expert_vs_greedy.run_many 200 7 in
      assert_equal 200 r.games_played );
    ( "same seed gives the same game" >:: fun _ ->
      assert_equal (Expert_vs_greedy.run_game 11) (Expert_vs_greedy.run_game 11)
    );
    ( "beats the random bot on average" >:: fun _ ->
      let r = Expert_vs_random.run_many 300 1 in
      assert_bool "expert > random" (avg r 0 > avg r 1) );
    ( "beats the greedy bot on average" >:: fun _ ->
      let r = Expert_vs_greedy.run_many 1000 1 in
      Printf.printf "\nExpert avg %.1f vs Greedy avg %.1f over 1000 games\n"
        (avg r 0) (avg r 1);
      assert_bool "expert > greedy" (avg r 0 > avg r 1) );
  ]

let suite =
  "Expert bot tests"
  >::: [
         "helpers" >::: helper_tests;
         "choose_keep" >::: keep_tests;
         "choose_category" >::: pick_tests;
         "games" >::: game_tests;
       ]

let () = run_test_tt_main suite
