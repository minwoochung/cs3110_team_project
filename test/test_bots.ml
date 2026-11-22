
open OUnit2
open Team_project

(** [make_obs values categories] is a bot observation
    with the given dice and legal scoring categories.

    The observation has two rerolls remaining and
    a new, empty scorecard. *)
let make_obs values categories : Bot_intf.observation =
  {
    dice = Dice.of_list values;
    scorecard = Scorecard.create ();
    rolls_remaining = 2;
    legal_categories = categories;
  }

(** [test_random_keep] checks that the random bot
    always returns a keep mask of length five. *)
let test_random_keep _ =
  let rng = Random.State.make [| 42 |] in
  let obs =
    make_obs [1; 2; 3; 4; 5] Categories.all
  in
  for _ = 1 to 100 do
    let keep = Random_bot.choose_keep rng obs in
    assert_equal 5 (List.length keep)
  done

(** [test_random_category] checks that the random bot
    selects only legally available categories. *)
let test_random_category _ =
  let rng = Random.State.make [| 42 |] in
  let categories =
    [Categories.Ones; Categories.Fours; Categories.Chance]
  in
  let obs = make_obs [1; 2; 3; 4; 5] categories in
  for _ = 1 to 100 do
    let category = Random_bot.choose_category rng obs in
    assert_bool
      "Random bot selected an illegal category"
      (List.mem category categories)
  done

(** [test_random_reproducible] checks that two random
    generators with the same seed produce identical
    decisions when given the same observations. *)
let test_random_reproducible _ =
  let rng1 = Random.State.make [| 42 |] in
  let rng2 = Random.State.make [| 42 |] in
  let obs =
    make_obs [1; 2; 3; 4; 5] Categories.all
  in
  for _ = 1 to 20 do
    let keep1 = Random_bot.choose_keep rng1 obs in
    let keep2 = Random_bot.choose_keep rng2 obs in
    assert_equal keep1 keep2;

    let category1 =
      Random_bot.choose_category rng1 obs
    in
    let category2 =
      Random_bot.choose_category rng2 obs
    in
    assert_equal category1 category2
  done

(** [test_keep_most_common] checks that all occurrences
    of the most frequent die value are kept. *)
let test_keep_most_common _ =
  let rng = Random.State.make [| 42 |] in
  let obs =
    make_obs [2; 5; 5; 3; 5] Categories.all
  in
  let actual = Keep_most_common.choose_keep rng obs in
  let expected = [false; true; true; false; true] in
  assert_equal expected actual

(** [test_keep_tie] checks that the smallest value
    is selected when multiple values have the same
    maximum frequency. *)
let test_keep_tie _ =
  let rng = Random.State.make [| 42 |] in
  let obs =
    make_obs [2; 2; 4; 4; 6] Categories.all
  in
  let actual = Keep_most_common.choose_keep rng obs in
  let expected = [true; true; false; false; false] in
  assert_equal expected actual

(** [test_keep_all_equal] checks that all five dice
    are kept when they have the same value. *)
let test_keep_all_equal _ =
  let rng = Random.State.make [| 42 |] in
  let obs =
    make_obs [6; 6; 6; 6; 6] Categories.all
  in
  let actual = Keep_most_common.choose_keep rng obs in
  assert_equal [true; true; true; true; true] actual

(** [test_greedy_keep] checks that the greedy bot
    uses the Keep-Most-Common reroll policy. *)
let test_greedy_keep _ =
  let rng = Random.State.make [| 42 |] in
  let obs =
    make_obs [3; 3; 3; 1; 5] Categories.all
  in
  let actual = Greedy_bot.choose_keep rng obs in
  assert_equal [true; true; true; false; false] actual

(** [test_greedy_category] checks that the greedy bot
    selects the available category with the highest
    immediate score. *)
let test_greedy_category _ =
  let rng = Random.State.make [| 42 |] in
  let categories =
    [
      Categories.Fours;
      Categories.Three_of_a_kind;
      Categories.Full_house;
      Categories.Chance;
    ]
  in
  let obs = make_obs [4; 4; 4; 2; 6] categories in
  let actual = Greedy_bot.choose_category rng obs in
  assert_equal Categories.Three_of_a_kind actual

(** [test_greedy_tie] checks that a scoring tie
    is resolved by choosing the first legal category. *)
let test_greedy_tie _ =
  let rng = Random.State.make [| 42 |] in
  let categories =
    [Categories.Chance; Categories.Three_of_a_kind]
  in
  let obs = make_obs [4; 4; 4; 2; 6] categories in
  let actual = Greedy_bot.choose_category rng obs in
  assert_equal Categories.Chance actual

(** [test_greedy_single_category] checks that the
    greedy bot selects the only available category. *)
let test_greedy_single_category _ =
  let rng = Random.State.make [| 42 |] in
  let obs =
    make_obs [1; 2; 3; 4; 5] [Categories.Ones]
  in
  let actual = Greedy_bot.choose_category rng obs in
  assert_equal Categories.Ones actual

(** [test_random_empty_categories] checks that the
    random bot rejects an empty list of categories. *)
let test_random_empty_categories _ =
  let rng = Random.State.make [| 42 |] in
  let obs = make_obs [1; 2; 3; 4; 5] [] in
  assert_raises
    (Invalid_argument
       "Random_bot.choose_category: no legal categories")
    (fun () -> ignore (Random_bot.choose_category rng obs))

(** [test_greedy_empty_categories] checks that the
    greedy bot rejects an empty list of categories. *)
let test_greedy_empty_categories _ =
  let rng = Random.State.make [| 42 |] in
  let obs = make_obs [1; 2; 3; 4; 5] [] in
  assert_raises
    (Invalid_argument
       "Greedy_bot.choose_category: no legal categories")
    (fun () -> ignore (Greedy_bot.choose_category rng obs))

let suite =
  "Bot Tests" >::: [
    "random_keep" >:: test_random_keep;
    "random_category" >:: test_random_category;
    "random_reproducible" >:: test_random_reproducible;
    "keep_most_common" >:: test_keep_most_common;
    "keep_tie" >:: test_keep_tie;
    "keep_all_equal" >:: test_keep_all_equal;
    "greedy_keep" >:: test_greedy_keep;
    "greedy_category" >:: test_greedy_category;
    "greedy_tie" >:: test_greedy_tie;
    "greedy_single_category" >:: test_greedy_single_category;
    "random_empty_categories" >:: test_random_empty_categories;
    "greedy_empty_categories" >:: test_greedy_empty_categories;
  ]

let () = run_test_tt_main suite
