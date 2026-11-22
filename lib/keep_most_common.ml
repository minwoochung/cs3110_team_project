
(** A reroll policy that keeps the most frequent die value.

    If multiple values have the same frequency, the
    smallest value is selected. *)

(** [most_common_value dice] is the value occurring most
    frequently in [dice].

    If multiple values have the same maximum frequency,
    the smallest value is returned. *)
let most_common_value (dice : Dice.t) : int =
  let rec find_best value best_value best_count =
    if value > 6 then best_value
    else
      let count = Scoring.count value dice in
      if count > best_count then
        find_best (value + 1) value count
      else
        find_best (value + 1) best_value best_count
  in
  find_best 1 1 0

(** [choose_keep rng obs] is a keep mask preserving all
    dice equal to the most frequent value in [obs.dice].

    Requires: [obs.rolls_remaining] > 0.

    The policy is deterministic and does not use [rng]. *)
let choose_keep
    (_rng : Random.State.t)
    (obs : Bot_intf.observation) : Dice.keep_mask =
  let target = most_common_value obs.dice in
  List.map
    (fun value -> value = target)
    (Dice.to_list obs.dice)
