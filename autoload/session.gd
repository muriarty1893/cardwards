extends Node
## Choices carried from the main menu into a match.

var player_deck: StringName = &"grove_guard"
## Empty = pick one of the other decks at random at match start.
var ai_deck: StringName = &""
var difficulty: AIPlayer.Difficulty = AIPlayer.Difficulty.MEDIUM
## Each player may redraw starting cards at the start of their first turn (tests turn it off).
var mulligan: bool = true
## 0 = new random seed each match. --seed=<n> on the command line fixes it.
var seed: int = 0


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			seed = int(arg.substr(7))


func match_seed() -> int:
	return seed if seed != 0 else int(Time.get_ticks_usec() % 2147483647)


func resolve_ai_deck(rng_seed: int) -> StringName:
	if ai_deck != &"":
		return ai_deck
	var others: Array[StringName] = []
	for id: StringName in CardDB.DECK_ORDER:
		if id != player_deck:
			others.append(id)
	return others[rng_seed % others.size()]
