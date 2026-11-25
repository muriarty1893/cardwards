class_name Fields
extends RefCounted
## Field spells (living board spec 8): one field in play for both players; its field_aura steps
## change stats, field_start / field_end steps run for the player whose turn it is.


## Plays a field: replaces the old one (to its owner's discard).
static func set_field(s: GameState, p: int, c: CardData, ev: Array[GameEvent]) -> void:
	var old: CardData = s.field
	if old:
		s.players[s.field_owner].discard.append(old)
	s.field = c
	s.field_owner = p
	ev.append(GameEvent.make(&"field_set", {"player": p, "card": c.id, "old": old.id if old else &""}))


static func _auras(s: GameState, op: StringName) -> Array[EffectData]:
	var out: Array[EffectData] = []
	if s.field:
		for e: EffectData in s.field.effects:
			if e.when == &"field_aura" and e.op == op:
				out.append(e)
	return out


static func _creature_land(s: GameState, p: int, lane: int) -> int:
	return s.players[p].lane(lane).land


## ATK change from the field for the creature in this lane.
static func atk_bonus(s: GameState, p: int, lane: int) -> int:
	if s.field == null or s.players[p].at(lane) == null:
		return 0
	var land: int = _creature_land(s, p, lane)
	var n: int = 0
	for e: EffectData in _auras(s, &"on_land_atk"):
		if land == e.filter_land:
			n += e.amount
	for e: EffectData in _auras(s, &"off_land_atk"):
		if land != e.filter_land:
			n += e.amount
	return n


static func hp_bonus(s: GameState, p: int, lane: int) -> int:
	if s.field == null or s.players[p].at(lane) == null:
		return 0
	var n: int = 0
	for e: EffectData in _auras(s, &"on_land_hp"):
		if _creature_land(s, p, lane) == e.filter_land:
			n += e.amount
	return n


## True when the field switches off the home quirk of `land` (Snowstorm: Ember Flats).
static func blocks_quirk(s: GameState, land: int) -> bool:
	if s.field == null:
		return false
	for e: EffectData in _auras(s, &"no_quirk"):
		if e.filter_land == land:
			return true
	return false


## Runs the field's `when` steps (field_start / field_end) for player p.
static func run(s: GameState, p: int, when: StringName, ev: Array[GameEvent]) -> void:
	if s.field == null or s.phase == GameState.Phase.OVER:
		return
	if not s.field.has_effect(when):
		return
	Effects.run(s, p, -1, s.field, when, [], ev)
