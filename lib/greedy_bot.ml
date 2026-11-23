
(** A greedy bot that keeps the most common die value
    and selects the highest-scoring available category. *)

(** [choose_keep rng obs] is the keep mask selected by
    the Keep-Most-Common reroll policy.

    Requires: [obs.rolls_remaining] > 0. *)
let choose_keep = Keep_most_common.choose_keep

(** [choose_category rng obs] is the available category
    with the highest immediate score for [obs.dice].

    If multiple categories have the same score, the first
    category in [obs.legal_categories] is selected.

    Requires: [obs.legal_categories] is nonempty. *)
let choose_category
    (_rng : Random.State.t)
    (obs : Bot_intf.observation) : Categories.t =
  match obs.legal_categories with
  | [] ->
      invalid_arg
        "Greedy_bot.choose_category: no legal categories"
  | first :: rest ->
      List.fold_left
        (fun best category ->
          let current_score =
            Scoring.score obs.dice category
          in
          let best_score =
            Scoring.score obs.dice best
          in
          if current_score > best_score then category
          else best)
        first rest
