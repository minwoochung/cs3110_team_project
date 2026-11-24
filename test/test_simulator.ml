open OUnit2
open Team_project

(** A simulator with one random bot. *)
module Single_bot = Simulator.Make (struct
  let bots = [ (module Random_bot : Bot_intf.BOT) ]
end)

(** A simulator with a random bot and a greedy bot. *)
module Two_bots = Simulator.Make (struct
  let bots =
    [ (module Random_bot : Bot_intf.BOT); (module Greedy_bot : Bot_intf.BOT) ]
end)

(** A simulator with no bots, used to test invalid input. *)
module No_bots = Simulator.Make (struct
  let bots = []
end)

(** [test_single_game] checks that a completed game returns one score for each
    participating bot. *)
let test_single_game _ =
  let result = Two_bots.run_game 42 in
  assert_equal 2 (List.length result.scores)

(** [test_nonnegative_scores] checks that completed games never return negative
    final scores. *)
let test_nonnegative_scores _ =
  let result = Two_bots.run_game 42 in
  List.iter
    (fun score -> assert_bool "Final score must be nonnegative" (score >= 0))
    result.scores

(** [test_single_bot_winner] checks that a game with one player always has that
    player as its winner. *)
let test_single_bot_winner _ =
  let result = Single_bot.run_game 42 in
  assert_equal 1 (List.length result.scores);
  assert_equal (Some 0) result.winner

(** [test_winner_valid] checks that the reported winner has the unique highest
    score, or that [None] indicates a tie for the highest score. *)
let test_winner_valid _ =
  let result = Two_bots.run_game 42 in
  match result.scores with
  | [ score0; score1 ] ->
      let expected =
        if score0 > score1 then Some 0
        else if score1 > score0 then Some 1
        else None
      in
      assert_equal expected result.winner
  | _ -> assert_failure "Expected exactly two scores"

(** [test_run_many_count] checks that the simulator records the requested number
    of completed games. *)
let test_run_many_count _ =
  let result = Two_bots.run_many 10 42 in
  assert_equal 10 result.games_played

(** [test_average_score_count] checks that the simulator reports one average per
    participating bot. *)
let test_average_score_count _ =
  let result = Two_bots.run_many 10 42 in
  assert_equal 2 (List.length result.average_scores)

(** [test_win_count] checks that wins and ties account for every completed game.
*)
let test_win_count _ =
  let result = Two_bots.run_many 10 42 in
  let total_wins = List.fold_left ( + ) 0 result.wins in
  assert_equal result.games_played (total_wins + result.ties)

(** [test_win_list_length] checks that the number of win counts equals the
    number of players. *)
let test_win_list_length _ =
  let result = Two_bots.run_many 10 42 in
  assert_equal 2 (List.length result.wins)

(** [test_single_game_reproducible] checks that simulations with the same seed
    return the same scores and winner. *)
let test_single_game_reproducible _ =
  let result1 = Two_bots.run_game 42 in
  let result2 = Two_bots.run_game 42 in
  assert_equal result1 result2

(** [test_run_many_reproducible] checks that repeated experiments with identical
    inputs return identical statistics. *)
let test_run_many_reproducible _ =
  let result1 = Two_bots.run_many 10 42 in
  let result2 = Two_bots.run_many 10 42 in
  assert_equal result1 result2

(** [test_average_matches_games] checks that the reported average scores equal
    the arithmetic means of individually simulated games. *)
let test_average_matches_games _ =
  let n = 5 in
  let seed = 42 in
  let result = Two_bots.run_many n seed in

  let totals = Array.make 2 0 in

  for i = 0 to n - 1 do
    let game = Two_bots.run_game (seed + i) in
    List.iteri
      (fun index score -> totals.(index) <- totals.(index) + score)
      game.scores
  done;

  let expected =
    Array.to_list
      (Array.map (fun total -> float_of_int total /. float_of_int n) totals)
  in

  assert_equal expected result.average_scores

(** [test_invalid_game_count] checks that requesting zero games raises
    [Invalid_argument]. *)
let test_invalid_game_count _ =
  assert_raises (Invalid_argument "Simulator.run_many: n must be positive")
    (fun () -> ignore (Two_bots.run_many 0 42))

(** [test_negative_game_count] checks that requesting a negative number of games
    raises [Invalid_argument]. *)
let test_negative_game_count _ =
  assert_raises (Invalid_argument "Simulator.run_many: n must be positive")
    (fun () -> ignore (Two_bots.run_many (-1) 42))

(** [test_no_bots] checks that a simulator with no participating bots rejects a
    game request. *)
let test_no_bots _ =
  assert_raises (Invalid_argument "Simulator.run_game: no bots") (fun () ->
      ignore (No_bots.run_game 42))

let suite =
  "Simulator Tests"
  >::: [
         "single_game" >:: test_single_game;
         "nonnegative_scores" >:: test_nonnegative_scores;
         "single_bot_winner" >:: test_single_bot_winner;
         "winner_valid" >:: test_winner_valid;
         "run_many_count" >:: test_run_many_count;
         "average_score_count" >:: test_average_score_count;
         "win_count" >:: test_win_count;
         "win_list_length" >:: test_win_list_length;
         "single_game_reproducible" >:: test_single_game_reproducible;
         "run_many_reproducible" >:: test_run_many_reproducible;
         "average_matches_games" >:: test_average_matches_games;
         "invalid_game_count" >:: test_invalid_game_count;
         "negative_game_count" >:: test_negative_game_count;
         "no_bots" >:: test_no_bots;
       ]

let () = run_test_tt_main suite
