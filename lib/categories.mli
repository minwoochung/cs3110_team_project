(** Scoring categories for Yahtzee. *)

(** The thirteen scoring categories in Yahtzee. *)
type t =
  | Ones
  | Twos
  | Threes
  | Fours
  | Fives
  | Sixes
  | Three_of_a_kind
  | Four_of_a_kind
  | Full_house
  | Small_straight
  | Large_straight
  | Yahtzee
  | Chance

(** [all] is a list containing all thirteen scoring categories
    exactly once, in the order defined above. *)
val all : t list

(** [is_upper category] is [true] if [category] is one of
    Ones, Twos, Threes, Fours, Fives, or Sixes.
    Otherwise, it is [false]. *)
val is_upper : t -> bool

(** [to_string category] is the human-readable name of
    [category], such as ["Three of a Kind"] or ["Yahtzee"]. *)
val to_string : t -> string

(** [of_string s] is [Some category] if [s] matches the
    name of a scoring category, ignoring case and leading
    or trailing whitespace. Otherwise, it is [None].

    The function accepts all names returned by [to_string]. *)
val of_string : string -> t option
