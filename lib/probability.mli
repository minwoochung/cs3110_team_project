(** Exact probabilities for rerolling Yahtzee dice.

    The functions in this module treat dice as a multiset: the order of the dice
    does not matter. Every [Dice.t] this module returns has its values in
    ascending order. *)

val outcomes : Dice.t -> Dice.keep_mask -> (Dice.t * float) list
(** [outcomes dice keep] is every distinct roll that can result from keeping the
    dice whose position in [keep] is [true] and rerolling the rest, paired with
    its probability. Each resulting roll appears once, with its values in
    ascending order, and the list is sorted by roll. Probabilities sum to 1.

    Raises: [Invalid_argument] if [keep] does not contain exactly five values.
*)

val outcomes_brute : Dice.t -> Dice.keep_mask -> (Dice.t * float) list
(** [outcomes_brute dice keep] is the same as [outcomes dice keep], computed by
    enumerating all 6^n ordered rerolls instead of using multinomial counts. It
    is slower and exists as an independent reference for tests.

    Raises: [Invalid_argument] if [keep] does not contain exactly five values.
*)

val prob_of : (Dice.t -> bool) -> Dice.t -> Dice.keep_mask -> float
(** [prob_of p dice keep] is the probability that the roll after keeping [keep]
    from [dice] and rerolling the rest satisfies [p]. For example,
    [prob_of Scoring.is_yahtzee dice keep].

    Raises: [Invalid_argument] if [keep] does not contain exactly five values.
*)

val expected : (Dice.t -> float) -> Dice.t -> Dice.keep_mask -> float
(** [expected f dice keep] is the expected value of [f] applied to the roll
    after keeping [keep] from [dice] and rerolling the rest.

    Raises: [Invalid_argument] if [keep] does not contain exactly five values.
*)
