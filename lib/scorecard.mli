
(** Scorecards and score tracking for Yahtzee.

    This module records scores, tracks available categories,
    and calculates bonuses and total scores.

    The Game module is responsible for checking whether
    a scoring action follows the rules of Yahtzee. *)

(** The type representing a player's scorecard.

    Each of the thirteen categories is either unused or
    contains a recorded score. The scorecard also tracks
    additional Yahtzee bonuses. *)
type t

(** [create ()] is a new scorecard in which all thirteen
    categories are unused and no bonuses have been earned. *)
val create : unit -> t

(** [get card category] is [None] if [category] has not
    been used, or [Some score] if [score] has been recorded
    in that category.

    [Some 0] means the category has been used and scored
    zero points. *)
val get : t -> Categories.t -> int option

(** [is_available card category] is [true] if [category]
    has not been used, and [false] otherwise. *)
val is_available : t -> Categories.t -> bool

(** [available_categories card] is the list of categories
    that have not been used, in the order of [Categories.all]. *)
val available_categories : t -> Categories.t list

(** [record_score card category score] is [Ok updated_card]
    with [score] recorded in [category].

    It is [Error message] if [category] has already been
    used or [score] is negative.

    This function does not calculate the score from dice.
    The Game module must validate the score before calling
    this function. *)
val record_score :
  t -> Categories.t -> int -> (t, string) result

(** [upper_subtotal card] is the sum of all recorded scores
    in the upper section (Ones through Sixes).

    Unused categories contribute zero to the subtotal. *)
val upper_subtotal : t -> int

(** [upper_bonus card] is [35] if the upper-section
    subtotal is at least [63], and [0] otherwise. *)
val upper_bonus : t -> int

(** [yahtzee_bonus card] is the total number of additional
    Yahtzee bonus points recorded on [card]. *)
val yahtzee_bonus : t -> int

(** [add_yahtzee_bonus card] is a new scorecard with
    an additional [100] Yahtzee bonus points.

    Requires: The Game module has verified that the player
    qualifies for an additional Yahtzee bonus under the
    standard Yahtzee rules.

    This function does not check the dice or Joker rules. *)
val add_yahtzee_bonus : t -> t

(** [total_score card] is the sum of all recorded category
    scores, the upper-section bonus, and any additional
    Yahtzee bonuses. *)
val total_score : t -> int

(** [is_complete card] is [true] if all thirteen scoring
    categories have been used, and [false] otherwise. *)
val is_complete : t -> bool
