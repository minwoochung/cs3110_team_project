open OUnit2
open Team_project

let eps = 1e-9
let cmp_float a b = Float.abs (a -. b) < eps

let assert_float ?msg exp act =
  assert_equal ?msg ~cmp:cmp_float ~printer:string_of_float exp act

let d = Dice.of_list
let all_keep = [ true; true; true; true; true ]
let none_keep = [ false; false; false; false; false ]
let keep_first3 = [ true; true; true; false; false ]

(* All 32 keep masks for five dice. *)
let all_masks =
  List.init 32 (fun m -> List.init 5 (fun i -> m land (1 lsl i) <> 0))

let sample_rolls =
  List.map d
    [
      [ 1; 2; 3; 4; 5 ]; [ 6; 6; 6; 6; 6 ]; [ 3; 1; 3; 5; 3 ]; [ 2; 2; 5; 5; 4 ];
    ]

(* Results as int lists, so they can be compared and printed. *)
let as_lists l = List.map (fun (r, p) -> (Dice.to_list r, p)) l
let sum_probs l = List.fold_left (fun acc (_, p) -> acc +. p) 0. l
let sum_dice r = float_of_int (Scoring.sum r)

let tests =
  "Probability"
  >::: [
         ( "keep all gives the same roll, sorted, with probability 1"
         >:: fun _ ->
           assert_equal
             [ ([ 1; 3; 3; 3; 5 ], 1.0) ]
             (as_lists (Probability.outcomes (d [ 3; 1; 3; 5; 3 ]) all_keep)) );
         ( "probabilities sum to 1 for every mask" >:: fun _ ->
           List.iter
             (fun r ->
               List.iter
                 (fun k ->
                   assert_float 1.0 (sum_probs (Probability.outcomes r k)))
                 all_masks)
             sample_rolls );
         ( "rerolling all five gives 252 distinct rolls" >:: fun _ ->
           assert_equal ~printer:string_of_int 252
             (List.length
                (Probability.outcomes (d [ 1; 1; 1; 1; 1 ]) none_keep)) );
         ( "rerolling all five: P(Yahtzee) = 6/7776" >:: fun _ ->
           assert_float (1. /. 1296.)
             (Probability.prob_of Scoring.is_yahtzee
                (d [ 1; 2; 3; 4; 5 ])
                none_keep) );
         ( "rerolling all five: expected sum = 17.5" >:: fun _ ->
           assert_float 17.5
             (Probability.expected sum_dice (d [ 1; 2; 3; 4; 5 ]) none_keep) );
         ( "keep three 6s: P(Yahtzee) = 1/36" >:: fun _ ->
           assert_float (1. /. 36.)
             (Probability.prob_of Scoring.is_yahtzee
                (d [ 6; 6; 6; 1; 2 ])
                keep_first3) );
         ( "keep three 6s: P(at least four 6s) = 11/36" >:: fun _ ->
           assert_float (11. /. 36.)
             (Probability.prob_of
                (fun r -> Scoring.count 6 r >= 4)
                (d [ 6; 6; 6; 1; 2 ])
                keep_first3) );
         ( "order of dice does not matter" >:: fun _ ->
           assert_equal
             (as_lists
                (Probability.outcomes
                   (d [ 2; 5; 5; 1; 1 ])
                   [ true; false; true; false; false ]))
             (as_lists
                (Probability.outcomes
                   (d [ 5; 5; 2; 1; 1 ])
                   [ true; false; true; false; false ])) );
         ( "multinomial and brute force agree" >:: fun _ ->
           List.iter
             (fun r ->
               List.iter
                 (fun k ->
                   let fast = as_lists (Probability.outcomes r k) in
                   let slow = as_lists (Probability.outcomes_brute r k) in
                   assert_equal (List.map fst slow) (List.map fst fast);
                   List.iter2 (fun (_, a) (_, b) -> assert_float a b) slow fast)
                 all_masks)
             sample_rolls );
         ( "keep mask of the wrong length raises" >:: fun _ ->
           assert_raises
             (Invalid_argument
                "Probability: keep mask must contain exactly five values")
             (fun () ->
               Probability.outcomes (d [ 1; 2; 3; 4; 5 ]) [ true; false ]) );
       ]

let () = run_test_tt_main tests
