class_name Tribes
extends RefCounted
## Creature tribes and their bonuses (living board spec 5): with 2 of a tribe you get tier 1,
## with 3 or more tier 2.

const ORDER: Array[StringName] = [&"beast", &"flyer", &"blob", &"sprout", &"spirit"]
const NAMES: Dictionary = {
	&"beast": "Beast", &"flyer": "Flyer", &"blob": "Blob", &"sprout": "Sprout", &"spirit": "Spirit",
}
const PLURALS: Dictionary = {
	&"beast": "Beasts", &"flyer": "Flyers", &"blob": "Blobs", &"sprout": "Sprouts", &"spirit": "Spirits",
}
## The bonus each tribe gives.
const BONUS: Dictionary = {
	&"beast": "Pack", &"flyer": "Flock", &"blob": "Squish", &"sprout": "Grove", &"spirit": "Haunt",
}
## Bonus at tier 1 and tier 2.
const BLOB_HP: Array[int] = [0, 2, 3]
const GROVE_HEAL: Array[int] = [0, 2, 3]


static func count(s: GameState, p: int, tribe: StringName) -> int:
	var n: int = 0
	for sp: int in s.players[p].creature_spots():
		if s.players[p].at(sp).card.tribe == tribe:
			n += 1
	return n


## Creatures of `tribe` player p controls other than the one in `except_lane`.
static func count_other(s: GameState, p: int, tribe: StringName, except_lane: int) -> int:
	var n: int = 0
	for i: int in GameState.SPOTS:
		var cr: GameState.CreatureState = s.players[p].at(i)
		if i != except_lane and cr and cr.card.tribe == tribe:
			n += 1
	return n


## 0 (fewer than 2), 1 (2) or 2 (3 or more).
static func tier(s: GameState, p: int, tribe: StringName) -> int:
	var n: int = count(s, p, tribe)
	return 0 if n < 2 else (1 if n == 2 else 2)


static func _tribe_at(s: GameState, p: int, lane: int) -> StringName:
	var cr: GameState.CreatureState = s.players[p].at(lane)
	return cr.card.tribe if cr else &""


## Pack: Beasts +1 / +2 ATK.
static func atk_bonus(s: GameState, p: int, lane: int) -> int:
	return tier(s, p, &"beast") if _tribe_at(s, p, lane) == &"beast" else 0


## Squish: Blobs +2 / +3 HP.
static func hp_bonus(s: GameState, p: int, lane: int) -> int:
	return BLOB_HP[tier(s, p, &"blob")] if _tribe_at(s, p, lane) == &"blob" else 0


## Flock: Flyers deal +1 / +2 damage when they attack the enemy hero.
static func hero_attack_bonus(s: GameState, p: int, lane: int) -> int:
	return tier(s, p, &"flyer") if _tribe_at(s, p, lane) == &"flyer" else 0


## Haunt: Spell Power +1 / +2.
static func spell_power(s: GameState, p: int) -> int:
	return tier(s, p, &"spirit")


## Grove: heal your hero 2 / 3 at the start of your turn.
static func grove_heal(s: GameState, p: int) -> int:
	return GROVE_HEAL[tier(s, p, &"sprout")]


## The bonus in words at a tier (1 or 2).
static func bonus_text(tribe: StringName, t: int) -> String:
	match tribe:
		&"beast":
			return "Your Beasts have +%d ATK." % t
		&"flyer":
			return "Your Flyers deal +%d damage to the enemy hero." % t
		&"blob":
			return "Your Blobs have +%d HP." % BLOB_HP[t]
		&"sprout":
			return "Heal your hero %d at the start of your turn." % GROVE_HEAL[t]
		&"spirit":
			return "Spell Power +%d." % t
	return ""


## "Pack (2 Beasts): Your Beasts have +1 ATK. 3+: +2 ATK." for tooltips.
static func rules_text(tribe: StringName) -> String:
	return "%s — with 2 %s: %s With 3 or more: %s" % [BONUS[tribe], PLURALS[tribe], bonus_text(tribe, 1), bonus_text(tribe, 2)]
