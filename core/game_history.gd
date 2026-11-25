class_name GameHistory
extends RefCounted
## The record of a game each player keeps (Dark Moon spec 3.2): spells cast, creatures lost,
## cards stolen, and what their deck started as. "This game" cards read it.


static func fresh() -> Dictionary:
	return {"spells": [] as Array[StringName], "spell_lands": [] as Array[int], "deaths_own": 0, "dead": [] as Array[StringName], "stolen": 0,
		"start_size": 0, "hero_hits": 0, "start_no_dupes": false, "start_ids": [] as Array[StringName]}


## Notes the starting deck (call before shuffling or drawing).
static func record_start(ps: GameState.PlayerState, cards: Array[CardData]) -> void:
	var ids: Array[StringName] = []
	var dupes: bool = false
	for c: CardData in cards:
		if c.id in ids:
			dupes = true
		else:
			ids.append(c.id)
	ps.history["start_size"] = cards.size()
	ps.history["start_no_dupes"] = not dupes and not cards.is_empty()
	ps.history["start_ids"] = ids


static func record_spell(ps: GameState.PlayerState, c: CardData) -> void:
	(ps.history["spells"] as Array).append(c.id)
	(ps.history["spell_lands"] as Array).append(c.land)


static func record_death(ps: GameState.PlayerState, c: CardData = null) -> void:
	ps.history["deaths_own"] = int(ps.history["deaths_own"]) + 1
	if c:
		(ps.history["dead"] as Array).append(c.id)


static func record_steal(ps: GameState.PlayerState, n: int = 1) -> void:
	ps.history["stolen"] = int(ps.history["stolen"]) + n


## Creatures that died this game, both sides.
static func deaths_all(s: GameState) -> int:
	return int(s.players[0].history["deaths_own"]) + int(s.players[1].history["deaths_own"])


## Spells of `land` player p cast this game (-1: any land).
static func spells_of_land(s: GameState, p: int, land: int) -> int:
	if land < 0:
		return (s.players[p].history["spells"] as Array).size()
	return (s.players[p].history["spell_lands"] as Array).count(land)


## The banner for a met starting-deck condition that one of p's cards cares about ("" for none).
static func start_banner(s: GameState, p: int) -> String:
	var ps: GameState.PlayerState = s.players[p]
	var wants: Dictionary = {}
	for c: CardData in ps.deck + ps.hand:
		for e: EffectData in c.effects:
			if e.need_cond != &"":
				wants[String(e.need_cond).get_slice(":", 0)] = true
	if wants.has("start_no_dupes") and bool(ps.history["start_no_dupes"]):
		return "NO DUPLICATES!"
	if wants.has("start_40") and int(ps.history["start_size"]) >= DeckStore.BIG_DECK_SIZE:
		return "40-CARD DECK!"
	return ""


static func started_with(s: GameState, p: int, id: StringName) -> bool:
	return id in (s.players[p].history["start_ids"] as Array)
