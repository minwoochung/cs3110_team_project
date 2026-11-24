(** The "Upper-Bonus Chaser" human-expert bot. See [expert_bot.mli] for a
    description of every rule. *)

let upper_categories = Categories.[ Ones; Twos; Threes; Fours; Fives; Sixes ]
let faces = [ 1; 2; 3; 4; 5; 6 ]

(** [upper_of_value v] is the upper category for face [v]. Requires: [v] is
    between 1 and 6. *)
let upper_of_value v = List.nth upper_categories (v - 1)

(** [face_value category] is the face counted by an upper category, or [0] for a
    lower category. *)
let face_value = function
  | Categories.Ones -> 1
  | Twos -> 2
  | Threes -> 3
  | Fours -> 4
  | Fives -> 5
  | Sixes -> 6
  | _ -> 0

let par = function
  | (Categories.Ones | Twos | Threes | Fours | Fives | Sixes) as c ->
      3 * face_value c
  | Three_of_a_kind -> 22
  | Four_of_a_kind -> 13
  | Full_house -> 23
  | Small_straight -> 30
  | Large_straight -> 33
  | Yahtzee -> 17
  | Chance -> 22

let bonus_push = 10

let bonus_live card =
  let subtotal = Scorecard.upper_subtotal card in
  let best_remaining =
    List.fold_left
      (fun acc c ->
        if Scorecard.is_available card c then acc + (5 * face_value c) else acc)
      0 upper_categories
  in
  subtotal < 63 && subtotal + best_remaining >= 63

let utility card dice category =
  let score = Scoring.score dice category in
  let base = score - par category in
  if Categories.is_upper category && score >= par category && bonus_live card
  then base + bonus_push
  else base

let longest_run dice =
  let values = Dice.to_list dice in
  let rec run_length v =
    if v <= 6 && List.mem v values then 1 + run_length (v + 1) else 0
  in
  List.fold_left
    (fun (best_start, best_len) start ->
      let len = run_length start in
      if len >= best_len then (start, len) else (best_start, best_len))
    (1, 0) faces

let target_value card dice =
  let key v =
    (Scoring.count v dice, Scorecard.is_available card (upper_of_value v), v)
  in
  List.fold_left
    (fun best v -> if compare (key v) (key best) > 0 then v else best)
    1 faces

(** [remove_one x lst] is [lst] with its first [x] removed. *)
let rec remove_one x = function
  | [] -> []
  | h :: t -> if h = x then t else h :: remove_one x t

(** [keep_one_each dice wanted] keeps one die for each value in [wanted] and
    rerolls the rest (used for straights). *)
let keep_one_each dice wanted =
  let _, mask =
    List.fold_left
      (fun (remaining, acc) d ->
        if List.mem d remaining then (remove_one d remaining, true :: acc)
        else (remaining, false :: acc))
      (wanted, []) (Dice.to_list dice)
  in
  List.rev mask

let choose_keep (_rng : Random.State.t) (obs : Bot_intf.observation) :
    Dice.keep_mask =
  let card = obs.scorecard in
  let dice = obs.dice in
  let values = Dice.to_list dice in
  let is_open = Scorecard.is_available card in
  let keep_all = List.map (fun _ -> true) values in
  let max_count =
    List.fold_left (fun m v -> max m (Scoring.count v dice)) 0 faces
  in
  let pairs = List.filter (fun v -> Scoring.count v dice = 2) faces in
  let run_start, run_len = longest_run dice in
  let straight_open =
    is_open Categories.Small_straight || is_open Categories.Large_straight
  in
  (* Rule 1: keep a finished hand that is worth keeping. *)
  if Scoring.is_yahtzee dice then keep_all
  else if Scoring.is_large_straight dice && is_open Large_straight then keep_all
  else if
    Scoring.is_small_straight dice
    && is_open Small_straight
    && not (is_open Large_straight)
  then keep_all
  else if Scoring.is_full_house dice && is_open Full_house then keep_all
    (* Rule 2: chase a straight. *)
  else if straight_open && (run_len >= 4 || (run_len = 3 && max_count = 1)) then
    keep_one_each dice (List.init run_len (fun i -> run_start + i))
    (* Rule 3: two pairs toward a full house. *)
  else if is_open Full_house && List.length pairs = 2 then
    List.map (fun d -> List.mem d pairs) values
  (* Rule 4: collect the target value. *)
    else
    let target = target_value card dice in
    List.map (fun d -> d = target) values

let choose_category (_rng : Random.State.t) (obs : Bot_intf.observation) :
    Categories.t =
  match obs.legal_categories with
  | [] -> invalid_arg "Expert_bot.choose_category: no legal categories"
  | first :: rest ->
      let u = utility obs.scorecard obs.dice in
      List.fold_left (fun best c -> if u c > u best then c else best) first rest
