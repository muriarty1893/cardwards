class_name Gifts
extends RefCounted
## Dark Gift bonuses (Dark Moon spec 3.3): each of the 3 offered creatures carries a different one.

const ORDER: Array[StringName] = [&"big", &"guard", &"leech", &"cheap", &"haunt"]
const TEXT: Dictionary = {
	&"big": "+2/+2", &"guard": "Guard", &"leech": "Leech", &"cheap": "Costs 2 less",
	&"haunt": "Last Breath: Summon a Glowmoth",
}
## The creature the "haunt" gift summons.
const WISP := &"glowmoth"


## The changes (for CardDB.variant) a gift makes.
static func delta(gift: StringName) -> Dictionary:
	match gift:
		&"big":
			return {"attack": 2, "health": 2, "gift": gift}
		&"guard":
			return {"keywords": [&"guard"], "gift": gift}
		&"leech":
			return {"keywords": [&"leech"], "gift": gift}
		&"cheap":
			return {"cost": -2, "gift": gift}
	return {"gift": gift}


## Extra ability steps a gift adds to the card.
static func effects(gift: StringName) -> Array[EffectData]:
	var out: Array[EffectData] = []
	if gift == &"haunt":
		var e := EffectData.new()
		e.when = &"on_destroyed"
		e.op = &"summon"
		e.amount = 1
		e.who = &"self"
		e.card_id = WISP
		out.append(e)
	return out
