(** A human-expert Yahtzee bot: the "Upper-Bonus Chaser".

    This bot plays the way an experienced human player does, using a small set
    of hand-written rules instead of probability calculations.

    Reroll rules, checked in order:
    + Keep a finished hand that is worth keeping: a Yahtzee, a Large Straight
      (if still open), a Small Straight (if Small Straight is open and Large
      Straight is not), or a Full House (if still open).
    + Chase a straight if Small or Large Straight is open and the dice contain
      four values in a row, or contain three values in a row with no repeated
      values.
    + Keep two pairs if Full House is open.
    + Otherwise, keep every die showing the target value (see [target_value]):
      the most common value, preferring values whose upper category is still
      open, then higher values.

    Scoring rule: pick the legal category with the highest [utility]. Utility
    compares the score against a "par" score for that category, so a weak roll
    is recorded where it costs the least (often Ones or Chance), and meeting par
    in the upper section earns an extra push while the 63-point bonus is still
    reachable. *)

val choose_keep : Random.State.t -> Bot_intf.observation -> Dice.keep_mask
(** [choose_keep rng obs] is the keep mask chosen by the expert reroll rules
    described above. The result always has exactly five entries.

    Requires: [obs.rolls_remaining] > 0.

    The policy is deterministic and does not use [rng]. *)

val choose_category : Random.State.t -> Bot_intf.observation -> Categories.t
(** [choose_category rng obs] is the category in [obs.legal_categories] with the
    highest [utility]. Ties go to the category that appears first in
    [obs.legal_categories].

    Requires: [obs.legal_categories] is nonempty.

    Raises: [Invalid_argument] if [obs.legal_categories] is empty.

    The policy is deterministic and does not use [rng]. *)

(** {1 Helpers}

    The functions below are exposed so the rules can be tested and explained on
    their own. *)

val par : Categories.t -> int
(** [par category] is the score the bot considers "on pace" for [category].

    For an upper category with face value [v], par is [3 * v]: three of each
    face is exactly the 63 points needed for the upper bonus. For lower
    categories, par is roughly the average score a strong player gets there. *)

val bonus_push : int
(** [bonus_push] is the extra utility the bot gives an upper category scored at
    or above par while the upper bonus is still live. *)

val bonus_live : Scorecard.t -> bool
(** [bonus_live card] is [true] if the upper bonus has not been earned yet on
    [card] but could still be earned by filling the open upper categories with
    five of each face. *)

val utility : Scorecard.t -> Dice.t -> Categories.t -> int
(** [utility card dice category] is how good the bot thinks it is to record
    [dice] in [category] given [card]:
    [Scoring.score dice category - par category], plus [bonus_push] if
    [category] is an upper category scored at or above par and [bonus_live card]
    holds. *)

val longest_run : Dice.t -> int * int
(** [longest_run dice] is [(start, length)] for the longest run of consecutive
    distinct values in [dice]. If two runs have the same length, the one with
    higher values is chosen. For example, [longest_run] of [3; 1; 4; 2; 6] is
    [(1, 4)]. *)

val target_value : Scorecard.t -> Dice.t -> int
(** [target_value card dice] is the face value the bot keeps when it is
    collecting matching dice. It has the highest count in [dice]; ties go to a
    value whose upper category is open on [card], then to the higher value. *)
