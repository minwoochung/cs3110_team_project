type t = int list

type keep_mask = bool list

let of_list values =
  if List.length values <> 5 then 
    invalid_arg "Dice.of_list expects exactly 5 dice"
  else if List.exists (fun x -> x < 1 || x > 6) values then 
    invalid_arg "Dice.of_list expects dice values between 1 and 6"
  else values


let to_list dice = dice

let roll rng = 
  let rec helper n = 
    if n = 0 then []
    else (Random.State.int rng 6 + 1) :: helper (n-1)
  in 
  helper 5


let reroll rng dice keep = 
  if List.length keep <> 5 then 
    invalid_arg "Dice.reroll expects a mask of length 5 for dice to keep"
else
  let values = 
    List.map2
      (fun die should_keep -> 
        if should_keep then die 
        else Random.State.int rng 6 + 1) 
      dice keep
  in 
  of_list values

