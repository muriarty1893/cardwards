class_name Conditions
extends RefCounted
## Player conditions a card step can need (EffectData.need_cond; Dark Moon spec 3.3).
## Written "name" or "name:arg[:arg]".


static func ok(s: GameState, p: int, cond: StringName) -> bool:
	if cond == &"":
		return true
	var bits: PackedStringArray = String(cond).split(":")
	var ps: GameState.PlayerState = s.players[p]
	match bits[0]:
		"start_no_dupes":
			return bool(ps.history["start_no_dupes"])
		"start_40":
			return int(ps.history["start_size"]) >= DeckStore.BIG_DECK_SIZE
		"started_with":
			return GameHistory.started_with(s, p, StringName(bits[1]))
		"holding_land":
			var land: int = int(bits[1])
			for c: CardData in ps.hand:
				if c.land == land:
					return true
			return false
		"holding_big":
			for c: CardData in ps.hand:
				if c.is_creature() and c.attack >= 6:
					return true
			return false
		"max_magic_at_least":
			return ps.max_magic >= int(bits[1])
		"deaths_at_least":
			return GameHistory.deaths_all(s) >= int(bits[1])
		"spells_of_land_at_least":
			return GameHistory.spells_of_land(s, p, int(bits[1])) >= int(bits[2])
	push_warning("Conditions: unknown '%s'" % cond)
	return false


## The condition in words, for card text ("If your deck started with no duplicates").
static func text(cond: StringName) -> String:
	var bits: PackedStringArray = String(cond).split(":")
	match bits[0]:
		"start_no_dupes":
			return "If your deck started with no duplicates"
		"start_40":
			return "If your deck started with 40 cards"
		"started_with":
			var id := StringName(bits[1])
			return "If %s started in your deck" % (CardDB.card(id).display_name if CardDB.has_card(id) else bits[1])
		"holding_land":
			return "If you're holding a %s card" % CardData.LAND_NAMES[int(bits[1])]
		"holding_big":
			return "If you're holding a creature with 6 or more ATK"
		"max_magic_at_least":
			return "If you have %s or more max magic" % bits[1]
		"deaths_at_least":
			return "If %s or more creatures died this game" % bits[1]
		"spells_of_land_at_least":
			return "If you've cast %s or more %s spells this game" % [bits[2], CardData.LAND_NAMES[int(bits[1])]]
	return "If " + String(cond)
