let sum dice = List.fold_left ( + ) 0 (Dice.to_list dice)

let count value dice =
  List.fold_left
    (fun acc die -> if die = value then acc + 1 else acc)
    0 (Dice.to_list dice)

let has_n_of_a_kind n dice =
  List.exists (fun value -> count value dice >= n) [ 1; 2; 3; 4; 5; 6 ]

let is_full_house dice =
  let counts = List.map (fun value -> count value dice) [ 1; 2; 3; 4; 5; 6 ] in
  List.mem 3 counts && List.mem 2 counts

let is_small_straight dice =
  let values = Dice.to_list dice in
  let has_sequence sequence =
    List.for_all (fun value -> List.mem value values) sequence
  in
  has_sequence [ 1; 2; 3; 4 ]
  || has_sequence [ 2; 3; 4; 5 ]
  || has_sequence [ 3; 4; 5; 6 ]

let is_large_straight dice =
  let values = Dice.to_list dice in
  let has_sequence sequence =
    List.for_all (fun value -> List.mem value values) sequence
  in
  has_sequence [ 1; 2; 3; 4; 5 ] || has_sequence [ 2; 3; 4; 5; 6 ]

let is_yahtzee dice = has_n_of_a_kind 5 dice

let score dice category =
  match category with
  | Categories.Ones -> count 1 dice
  | Categories.Twos -> 2 * count 2 dice
  | Categories.Threes -> 3 * count 3 dice
  | Categories.Fours -> 4 * count 4 dice
  | Categories.Fives -> 5 * count 5 dice
  | Categories.Sixes -> 6 * count 6 dice
  | Categories.Three_of_a_kind -> if has_n_of_a_kind 3 dice then sum dice else 0
  | Categories.Four_of_a_kind -> if has_n_of_a_kind 4 dice then sum dice else 0
  | Categories.Full_house -> if is_full_house dice then 25 else 0
  | Categories.Small_straight -> if is_small_straight dice then 30 else 0
  | Categories.Large_straight -> if is_large_straight dice then 40 else 0
  | Categories.Yahtzee -> if is_yahtzee dice then 50 else 0
  | Categories.Chance -> sum dice
