
(** Shared interfaces for Yahtzee bot strategies.

    A bot consists of a reroll policy and a scoring policy.
    These policies can be implemented independently and
    combined to create different bots. *)

(** The information available to a bot when making a decision.

    [dice] contains the current five dice.

    [scorecard] is the current player's scorecard.

    [rolls_remaining] is the number of rerolls still
    available during the current turn.

    [legal_categories] contains the categories in which
    the player may legally record a score. *)
type observation = {
  dice : Dice.t;
  scorecard : Scorecard.t;
  rolls_remaining : int;
  legal_categories : Categories.t list;
}

(** The interface for strategies that select dice to keep. *)
module type REROLL_POLICY = sig
  (** [choose_keep rng obs] is a keep mask indicating which
      dice to preserve when rerolling.

      [true] means keep the corresponding die, and [false]
      means reroll it.

      The result contains exactly five boolean values.

      Requires: [obs.rolls_remaining] > 0.

      The policy may use [rng] for randomized decisions. *)
  val choose_keep :
    Random.State.t -> observation -> Dice.keep_mask
end

(** The interface for strategies that select a scoring category. *)
module type SCORE_POLICY = sig
  (** [choose_category rng obs] is a scoring category
      selected from [obs.legal_categories].

      Requires: [obs.legal_categories] is nonempty.

      The policy may use [rng] for randomized decisions. *)
  val choose_category :
    Random.State.t -> observation -> Categories.t
end

(** The interface for a complete Yahtzee bot. *)
module type BOT = sig
  (** [choose_keep rng obs] is the keep mask selected by
      the bot's reroll policy.

      Requires: [obs.rolls_remaining] > 0. *)
  val choose_keep :
    Random.State.t -> observation -> Dice.keep_mask

  (** [choose_category rng obs] is the category selected
      by the bot's scoring policy.

      Requires: [obs.legal_categories] is nonempty. *)
  val choose_category :
    Random.State.t -> observation -> Categories.t
end

(** [Make_bot] combines a reroll policy and a scoring
    policy into a complete bot.

    The resulting bot uses the reroll policy to select
    dice to keep and the scoring policy to select a
    category in which to record a score. *)
module Make_bot
    (R : REROLL_POLICY)
    (S : SCORE_POLICY) : BOT
