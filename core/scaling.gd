class_name Scaling
extends RefCounted
## Counts a card step can grow with (EffectData.scale): "Deal 1 damage, +1 for each time your
## hero took damage this game", "Deal damage equal to your armour". Counted for player p when
## the step runs; `lane` is the source creature's spot (-1 for spells and buildings).

const ALL: Array[StringName] = [&"hero_hits", &"enemy_hero_hits", &"armour", &"deaths", &"own_deaths",
	&"spells", &"hand", &"own_creatures", &"enemy_creatures", &"missing_hp", &"stolen", &"max_magic",
	&"self_atk", &"self_hp", &"cards_played"]


static func value(s: GameState, p: int, lane: int, scale: StringName) -> int:
	var ps: GameState.PlayerState = s.players[p]
	var foe: GameState.PlayerState = s.players[s.opponent(p)]
	match scale:
		&"hero_hits":
			return int(ps.history.get("hero_hits", 0))
		&"enemy_hero_hits":
			return int(foe.history.get("hero_hits", 0))
		&"armour":
			return ps.armour
		&"deaths":
			return GameHistory.deaths_all(s)
		&"own_deaths":
			return int(ps.history["deaths_own"])
		&"spells":
			return (ps.history["spells"] as Array).size()
		&"hand":
			return ps.hand.size()
		&"own_creatures":
			return _count(ps, lane)
		&"enemy_creatures":
			return _count(foe, -1)
		&"missing_hp":
			return maxi(GameState.MAX_HP - ps.hero_hp, 0)
		&"stolen":
			return int(ps.history["stolen"])
		&"max_magic":
			return ps.max_magic
		&"self_atk":
			return Rules.effective_attack(s, p, lane) if lane >= 0 and ps.at(lane) else 0
		&"self_hp":
			return Rules.effective_max_hp(s, p, lane) - ps.at(lane).damage if lane >= 0 and ps.at(lane) else 0
		&"cards_played":
			return ps.cards_played
	push_warning("Scaling: unknown '%s'" % scale)
	return 0


## Creatures p controls, not counting the one at `skip`.
static func _count(ps: GameState.PlayerState, skip: int) -> int:
	var n: int = 0
	for l: int in GameState.SPOTS:
		if l != skip and ps.at(l):
			n += 1
	return n


## What the count is, for card text: "for each time your hero took damage this game" reads
## "+N <each>", "equal to <total>" reads with amount 0.
static func each_text(scale: StringName) -> String:
	match scale:
		&"hero_hits": return "for each time your hero took damage this game"
		&"enemy_hero_hits": return "for each time the enemy hero took damage this game"
		&"armour": return "for each armour you have"
		&"deaths": return "for each creature that died this game"
		&"own_deaths": return "for each of your creatures that died this game"
		&"spells": return "for each spell you've cast this game"
		&"hand": return "for each card in your hand"
		&"own_creatures": return "for each other creature you control"
		&"enemy_creatures": return "for each enemy creature"
		&"missing_hp": return "for each HP your hero is missing"
		&"stolen": return "for each card you've stolen this game"
		&"max_magic": return "for each max magic you have"
		&"self_atk": return "for each ATK this has"
		&"self_hp": return "for each HP this has"
		&"cards_played": return "for each other card you played this turn"
	return "for each " + String(scale)


static func total_text(scale: StringName) -> String:
	match scale:
		&"hero_hits": return "the number of times your hero took damage this game"
		&"enemy_hero_hits": return "the number of times the enemy hero took damage this game"
		&"armour": return "your armour"
		&"deaths": return "the number of creatures that died this game"
		&"own_deaths": return "the number of your creatures that died this game"
		&"spells": return "the number of spells you've cast this game"
		&"hand": return "the number of cards in your hand"
		&"own_creatures": return "the number of other creatures you control"
		&"enemy_creatures": return "the number of enemy creatures"
		&"missing_hp": return "the HP your hero is missing"
		&"stolen": return "the number of cards you've stolen this game"
		&"max_magic": return "your max magic"
		&"self_atk": return "this creature's ATK"
		&"self_hp": return "this creature's HP"
		&"cards_played": return "the number of other cards you played this turn"
	return String(scale)
