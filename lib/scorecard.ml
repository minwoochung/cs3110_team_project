type t = {
  scores : (Categories.t * int) list;
  yahtzee_bonuses : int;
}

let create () = { scores = []; yahtzee_bonuses = 0 }
let get card category = List.assoc_opt category card.scores
let is_available card category = get card category = None

let available_categories card =
  List.filter (fun category -> is_available card category) Categories.all

let record_score card category score =
  if score < 0 then Error "Score cannot be negative"
  else if not (is_available card category) then
    Error "Category has already been used"
  else Ok { card with scores = (category, score) :: card.scores }

let upper_subtotal card =
  List.fold_left
    (fun total (category, score) ->
      if Categories.is_upper category then total + score else total)
    0 card.scores

let upper_bonus card = if upper_subtotal card >= 63 then 35 else 0
let yahtzee_bonus card = card.yahtzee_bonuses

let add_yahtzee_bonus card =
  { card with yahtzee_bonuses = card.yahtzee_bonuses + 100 }

let total_score card =
  let category_total =
    List.fold_left (fun total (_, score) -> total + score) 0 card.scores
  in
  category_total + upper_bonus card + yahtzee_bonus card

let is_complete card =
  List.for_all (fun category -> not (is_available card category)) Categories.all
