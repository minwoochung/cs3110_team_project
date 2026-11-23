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

let all = [
  Ones;
    Twos;
    Threes;
    Fours;
    Fives;
    Sixes;
    Three_of_a_kind;
    Four_of_a_kind;
    Full_house;
    Small_straight;
    Large_straight;
    Yahtzee;
    Chance;
]

let is_upper = function
  | Ones | Twos | Threes | Fours | Fives | Sixes -> true
  | _ -> false


let to_string = function 
  | Ones -> "Ones"
  | Twos -> "Twos"
  | Threes -> "Threes"
  | Fours -> "Fours"
  | Fives -> "Fives"
  | Sixes -> "Sixes"
  | Three_of_a_kind -> "Three of a Kind"
  | Four_of_a_kind -> "Four of a Kind"
  | Full_house -> "Full House"
  | Small_straight -> "Small Straight"
  | Large_straight -> "Large Straight"
  | Yahtzee -> "Yahtzee"
  | Chance -> "Chance"

let of_string s =
  let res = String.lowercase_ascii (String.trim s) in
  List.find_opt
    (fun category ->
      String.lowercase_ascii (to_string category) = res)
    all