(* Internally, dice are int lists of faces 1..6, kept sorted so that each
   multiset has exactly one representation. *)

let sort l = List.sort compare l

(* [range lo hi] is [lo; lo+1; ...; hi], or [] if [lo > hi]. *)
let rec range lo hi = if lo > hi then [] else lo :: range (lo + 1) hi
let rec factorial n = if n <= 1 then 1 else n * factorial (n - 1)
let rec pow b e = if e = 0 then 1 else b * pow b (e - 1)

(* [counts d] is an array whose element [i] is how many dice in [d] show face [i
   + 1]. *)
let counts d =
  let a = Array.make 6 0 in
  List.iter (fun f -> a.(f - 1) <- a.(f - 1) + 1) d;
  a

(* [multisets n lo] is every sorted list of [n] faces, each at least [lo].
   Requiring the rest of the list to start at [f] or higher is what keeps each
   multiset from appearing more than once. *)
let rec multisets n lo =
  if n = 0 then [ [] ]
  else
    List.concat_map
      (fun f -> List.map (fun rest -> f :: rest) (multisets (n - 1) f))
      (range lo 6)

(* [ways ms] is how many ordered rolls of [List.length ms] dice produce the
   multiset [ms]: n! / (c1! * c2! * ... * c6!). *)
let ways ms =
  let n = List.length ms in
  Array.fold_left (fun acc c -> acc / factorial c) (factorial n) (counts ms)

(* [split dice keep] checks [keep] and returns the kept faces and the number of
   dice to reroll. *)
let split dice keep =
  if List.length keep <> 5 then
    invalid_arg "Probability: keep mask must contain exactly five values";
  let kept =
    List.combine (Dice.to_list dice) keep
    |> List.filter_map (fun (f, k) -> if k then Some f else None)
  in
  (kept, 5 - List.length kept)

(* [finish l] converts a list of (sorted faces, probability) pairs into the
   result type, sorted by roll. *)
let finish l =
  l
  |> List.sort (fun (a, _) (b, _) -> compare a b)
  |> List.map (fun (faces, p) -> (Dice.of_list faces, p))

let outcomes dice keep =
  let kept, n = split dice keep in
  let total = float_of_int (pow 6 n) in
  (* Different multisets of new dice added to the same kept dice give different
     final rolls, so no merging is needed. *)
  multisets n 1
  |> List.map (fun ms -> (sort (kept @ ms), float_of_int (ways ms) /. total))
  |> finish

(* [sequences n] is every ordered list of [n] faces: 6^n lists. *)
let rec sequences n =
  if n = 0 then [ [] ]
  else
    List.concat_map
      (fun f -> List.map (fun rest -> f :: rest) (sequences (n - 1)))
      (range 1 6)

let outcomes_brute dice keep =
  let kept, n = split dice keep in
  let tbl = Hashtbl.create 256 in
  List.iter
    (fun s ->
      let r = sort (kept @ s) in
      let c = try Hashtbl.find tbl r with Not_found -> 0 in
      Hashtbl.replace tbl r (c + 1))
    (sequences n);
  let total = float_of_int (pow 6 n) in
  Hashtbl.fold (fun r c acc -> (r, float_of_int c /. total) :: acc) tbl []
  |> finish

let prob_of p dice keep =
  List.fold_left
    (fun acc (r, pr) -> if p r then acc +. pr else acc)
    0. (outcomes dice keep)

let expected f dice keep =
  List.fold_left (fun acc (r, pr) -> acc +. (pr *. f r)) 0. (outcomes dice keep)
