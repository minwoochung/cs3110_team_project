(** Text rendering and input parsing for the terminal interface. *)

(** [render_dice dice] renders dice as two rows: one-based positions
    above, die values below. *)
val render_dice : Dice.t option -> string

(** [render_scorecard card] renders all categories and the score totals. *)
val render_scorecard : Scorecard.t -> string

(** [render_game state] renders a compact summary: turn, rolls remaining,
    dice, and player totals. The current player's full scorecard is
    included only when no rolls remain and a category must be chosen. *)
val render_game : Game.game_state -> string

(** [render_score_menu card dice categories] renders a numbered menu of
    [categories], each with the points [dice] would score there, plus
    the total of [card]. The numbers match [parse_category]. *)
val render_score_menu :
  Scorecard.t -> Dice.t option -> Categories.t list -> string

(** [render_turn_banner name] is a heading announcing [name]'s turn. *)
val render_turn_banner : string -> string

(** [render_bot_roll name roll_number dice keep] renders one roll of a
    bot's turn: the dice, and when [keep] is [Some mask], a [^] marker
    under each kept die and a sentence saying which dice are kept. Use
    [None] for the final roll, when the bot scores instead of rerolling. *)
val render_bot_roll :
  string -> int -> Dice.t -> Dice.keep_mask option -> string

(** [render_bot_score name dice category] is a sentence saying that
    [name] scored [dice] in [category], with the points earned. *)
val render_bot_score : string -> Dice.t -> Categories.t -> string

(** [parse_keep_positions input] parses one-based die positions to keep.
    ["none"] means reroll all dice and ["all"] means keep all dice.
    Positions may be separated by spaces or commas. Empty input is invalid. *)
val parse_keep_positions : string -> (Dice.keep_mask, string) result

(** [parse_category categories input] parses either a one-based menu
    number or the name of a category in [categories]. *)
val parse_category :
  Categories.t list -> string -> (Categories.t, string) result