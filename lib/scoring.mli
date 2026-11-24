(** Scoring rules for Yahtzee.

    This module computes the scores of dice combinations. It does not modify
    scorecards or game states. *)

val score : Dice.t -> Categories.t -> int
(** [score dice category] is the score obtained by assigning [dice] to
    [category] according to the standard Yahtzee scoring rules.

    Upper categories (Ones through Sixes) score the sum of dice matching the
    category's number.

    Three_of_a_kind and Four_of_a_kind score the sum of all five dice if the
    required number of matching dice exists, and [0] otherwise.

    Full_house scores [25] for exactly three dice of one value and two of
    another.

    Small_straight scores [30] if at least four consecutive values are present.

    Large_straight scores [40] if five consecutive values are present.

    Yahtzee scores [50] if all five dice have the same value.

    Chance scores the sum of all five dice.

    This function computes the ordinary category score only. Upper-section
    bonuses, additional Yahtzee bonuses, and Joker rules are handled separately
    using the scorecard.

    It does not check whether [category] has already been used. *)

val sum : Dice.t -> int
(** [sum dice] is the sum of the five values in [dice]. *)

val count : int -> Dice.t -> int
(** [count value dice] is the number of dice in [dice] whose value equals
    [value].

    Requires: [value] is between [1] and [6]. *)

val has_n_of_a_kind : int -> Dice.t -> bool
(** [has_n_of_a_kind n dice] is [true] if at least [n] dice have the same value,
    and [false] otherwise.

    Requires: [n] is between [1] and [5]. *)

val is_full_house : Dice.t -> bool
(** [is_full_house dice] is [true] if [dice] contains exactly three dice of one
    value and two dice of another value. Otherwise, it is [false]. *)

val is_small_straight : Dice.t -> bool
(** [is_small_straight dice] is [true] if [dice] contains at least four
    consecutive distinct values. Otherwise, it is [false]. *)

val is_large_straight : Dice.t -> bool
(** [is_large_straight dice] is [true] if [dice] contains five consecutive
    distinct values. Otherwise, it is [false]. *)

val is_yahtzee : Dice.t -> bool
(** [is_yahtzee dice] is [true] if all five dice have the same value, and
    [false] otherwise. *)
