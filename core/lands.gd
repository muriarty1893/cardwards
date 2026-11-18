class_name Lands
extends RefCounted
## Lanes and their lands (living board spec 2-4): every lane starts as Meadow, cards claim it,
## creatures at home on their own land get its quirk, and spells react with the land under
## their target.

const MEADOW := CardData.Land.NEUTRAL
## Home quirk per land (MUSHROOM, EMBER, CANDY, FROST).
const QUIRKS: Array[String] = ["Rooted", "Fired up", "Plump", "Ice skin"]
const QUIRK_RULES: Array[String] = [
	"Heals 2 at the start of your turn.",
	"+1 ATK.",
	"+1 ATK and +1 HP.",
	"Takes 1 less damage from attacks and hit-back (minimum 1).",
]
## Spell land → lane land → reaction (spec 4).
const REACTIONS: Dictionary = {
	CardData.Land.EMBER: {CardData.Land.FROST: &"melt", CardData.Land.MUSHROOM: &"wildfire", CardData.Land.CANDY: &"caramel"},
	CardData.Land.FROST: {CardData.Land.EMBER: &"quench"},
	CardData.Land.MUSHROOM: {CardData.Land.MUSHROOM: &"bloom", CardData.Land.NEUTRAL: &"sprout"},
}
const REACTION_NAMES: Dictionary = {
	&"melt": "Melt", &"wildfire": "Wildfire", &"caramel": "Caramel", &"quench": "Quench",
	&"bloom": "Bloom", &"sprout": "Sprout",
}
const REACTION_RULES: Dictionary = {
	&"melt": "Fire on Frostpeak: +1 damage, and the lane thaws",
	&"wildfire": "Fire in the forest: 1 damage to the next lanes too",
	&"caramel": "Fire on Candy Hills: stuck in caramel (frozen)",
	&"quench": "Frost on Ember Flats: the lava cools to Meadow",
	&"bloom": "Spores on Mushroom Forest: heals 2 more",
	&"sprout": "Spores on Meadow: it grows into Mushroom Forest",
}


## The lane's land as shown on the board ("Meadow" for bare lanes).
static func lane_name(land: int) -> String:
	return "Meadow" if land == MEADOW else CardData.LAND_NAMES[land]


static func set_land(s: GameState, p: int, lane: int, land: int, cause: StringName, ev: Array[GameEvent]) -> void:
	var ls: GameState.LaneState = s.players[p].lanes[lane]
	if ls.land == land:
		return
	var from: int = ls.land
	ls.land = land
	ev.append(GameEvent.make(&"land_changed", {"player": p, "lane": lane, "land": land, "from": from, "cause": cause}))


## A creature or building played into `lane` claims a Meadow lane; a building also converts a
## lane of another land.
static func claim(s: GameState, p: int, lane: int, c: CardData, ev: Array[GameEvent]) -> void:
	if c.land == MEADOW or c.kind == CardData.Kind.SPELL:
		return
	var current: int = s.players[p].lanes[lane].land
	if current == MEADOW:
		set_land(s, p, lane, c.land, &"claim", ev)
	elif c.kind == CardData.Kind.BUILDING and current != c.land:
		set_land(s, p, lane, c.land, &"building", ev)


## Lanes of `land` player p would have with a card of that land played into `lane` (spec 2:
## the lane counts if it is Meadow or already that land).
static func count_after_play(s: GameState, p: int, lane: int, land: int) -> int:
	var n: int = Rules.matching_lands(s, p, land)
	if lane >= 0 and lane < GameState.LANES and s.players[p].lanes[lane].land == MEADOW:
		n += 1
	return n


## The land whose quirk the creature in this lane gets, or -1 when it is not at home (or the
## field switches that land's quirk off).
static func home(s: GameState, p: int, lane: int) -> int:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	if cr == null:
		return -1
	var land: int = s.players[p].lanes[lane].land
	if land == MEADOW or land != cr.card.land or Fields.blocks_quirk(s, land):
		return -1
	return land


static func is_home(s: GameState, p: int, lane: int) -> bool:
	return home(s, p, lane) >= 0


## The reaction a spell of `spell_land` sets off on a lane of `lane_land`, or &"".
static func reaction(spell_land: int, lane_land: int) -> StringName:
	var row: Dictionary = REACTIONS.get(spell_land, {})
	return row.get(lane_land, &"")


## Reaction for a spell effect on a creature target, before the effect lands. Returns the extra
## amount (Melt +1 damage, Bloom +2 heal) and appends the reaction event.
static func react_before(s: GameState, card: CardData, op: StringName, t: Dictionary, ev: Array[GameEvent]) -> Dictionary:
	if card.kind != CardData.Kind.SPELL or card.field or not t.has("lane") or not t.has("player"):
		return {}
	var p: int = t["player"]
	var lane: int = t["lane"]
	var r: StringName = reaction(card.land, s.players[p].lanes[lane].land)
	if r == &"":
		return {}
	# Each reaction answers to the kind of step it fits: damage for fire, heal for spores, any
	# step for frost (freeze or damage).
	match r:
		&"melt", &"wildfire", &"caramel":
			if op != &"damage":
				return {}
		&"bloom", &"sprout":
			if op != &"heal":
				return {}
		&"quench":
			if op != &"damage" and op != &"freeze":
				return {}
	ev.append(GameEvent.make(&"land_reaction", {"player": p, "lane": lane, "reaction": r, "card": card.id}))
	var extra: int = 0
	if r == &"melt":
		extra = 1
	elif r == &"bloom":
		extra = 2
	return {"reaction": r, "extra": extra}


## The reaction's after-effect on the lane and its neighbours.
static func react_after(s: GameState, src_player: int, info: Dictionary, t: Dictionary, ev: Array[GameEvent]) -> void:
	if info.is_empty():
		return
	var p: int = t["player"]
	var lane: int = t["lane"]
	match info["reaction"]:
		&"melt", &"quench":
			set_land(s, p, lane, MEADOW, info["reaction"], ev)
		&"sprout":
			set_land(s, p, lane, CardData.Land.MUSHROOM, &"sprout", ev)
		&"caramel":
			Rules.freeze(s, p, lane, ev)
		&"wildfire":
			for n: int in [lane - 1, lane + 1]:
				if n >= 0 and n < GameState.LANES and s.players[p].lanes[n].creature:
					Rules.damage_creature(s, p, n, 1, {"player": src_player, "lane": -1, "kind": &"spell"}, ev)
