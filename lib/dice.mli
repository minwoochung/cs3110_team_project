(** Dice operations for Yahtzee. *)

(** The type representing five six-sided dice.

    Each die has a value between 1 and 6. *)
type t

(** The type representing which dice to keep when rerolling.

    A value of [true] means the die at that position is kept.
    A value of [false] means the die is rerolled. *)
type keep_mask = bool list

(** [of_list values] is the dice represented by [values].

    Requires: [values] contains exactly five integers,
    each between 1 and 6.

    Raises: [Invalid_argument] if the precondition is
    violated. *)
val of_list : int list -> t

(** [to_list dice] is the list of five die values in [dice],
    preserving their original order. *)
val to_list : t -> int list

(** [roll rng] generates five random dice using [rng].

    Each die is independently and uniformly distributed
    over the integers from 1 to 6. *)
val roll : Random.State.t -> t

(** [reroll rng dice keep] is a new set of dice obtained
    by keeping the dice whose corresponding values in
    [keep] are [true] and rerolling the remaining dice
    using [rng].

    The positions of kept dice are preserved.

    Requires: [keep] contains exactly five boolean values.

    Raises: [Invalid_argument] if [keep] does not contain
    exactly five values. *)
val reroll : Random.State.t -> t -> keep_mask -> t
