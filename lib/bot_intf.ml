
(** Shared interfaces and composition of Yahtzee bot policies. *)

type observation = {
  dice : Dice.t;
  scorecard : Scorecard.t;
  rolls_remaining : int;
  legal_categories : Categories.t list;
}

module type REROLL_POLICY = sig
  val choose_keep :
    Random.State.t -> observation -> Dice.keep_mask
end

module type SCORE_POLICY = sig
  val choose_category :
    Random.State.t -> observation -> Categories.t
end

module type BOT = sig
  val choose_keep :
    Random.State.t -> observation -> Dice.keep_mask

  val choose_category :
    Random.State.t -> observation -> Categories.t
end

(** [Make_bot] combines a reroll policy and a scoring
    policy into one complete bot. *)
module Make_bot
    (R : REROLL_POLICY)
    (S : SCORE_POLICY) = struct
  let choose_keep = R.choose_keep
  let choose_category = S.choose_category
end
