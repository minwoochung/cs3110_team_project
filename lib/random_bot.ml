(** A baseline bot that makes random decisions. *)

(** [choose_keep rng obs] randomly chooses which dice to keep. Each die has an
    equal probability of being kept or rerolled.

    Requires: [obs.rolls_remaining] > 0. *)
let choose_keep rng (_obs : Bot_intf.observation) : Dice.keep_mask =
  List.init 5 (fun _ -> Random.State.bool rng)

(** [choose_category rng obs] randomly selects one of the available scoring
    categories.

    Requires: [obs.legal_categories] is nonempty. *)
let choose_category rng (obs : Bot_intf.observation) : Categories.t =
  let categories = obs.legal_categories in
  match categories with
  | [] -> invalid_arg "Random_bot.choose_category: no legal categories"
  | _ ->
      let index = Random.State.int rng (List.length categories) in
      List.nth categories index
