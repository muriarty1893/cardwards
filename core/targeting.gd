class_name Targeting
extends RefCounted
## Who an effect reaches (EffectData.who): the choices a player may make, and the automatic
## groups. Creatures are {"player", "lane"}, heroes {"hero": player}, discard picks {"discard": i}.

const CHOSEN: Array[StringName] = [
	&"chosen_creature", &"chosen_own_creature", &"chosen_own_empty_lane",
	&"chosen_two_own_creatures", &"chosen_discard_creature",
	&"chosen_enemy_creature", &"chosen_damaged_enemy", &"chosen_undamaged_creature", &"chosen_frozen_enemy",
]


## The first chosen_* who among the card's effects for `when`, else &"".
static func chosen_who(c: CardData, when: StringName) -> StringName:
	for e: EffectData in c.effects_for(when):
		if e.who in CHOSEN:
			return e.who
	return &""


static func needed(who: StringName) -> int:
	return 2 if who == &"chosen_two_own_creatures" else 1


## Everything player `p` may choose for `who`. Enemy Hidden creatures cannot be chosen.
static func valid(s: GameState, p: int, who: StringName, source_lane: int = -1) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match who:
		&"chosen_creature":
			for q: int in [p, s.opponent(p)]:
				for l: int in GameState.SPOTS:
					var cr: GameState.CreatureState = s.players[q].at(l)
					if cr and not (q != p and cr.hidden):
						out.append({"player": q, "lane": l})
			out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
				return a["player"] < b["player"] if a["player"] != b["player"] else a["lane"] < b["lane"])
		&"chosen_own_creature", &"chosen_two_own_creatures":
			for l: int in GameState.SPOTS:
				if s.players[p].at(l):
					out.append({"player": p, "lane": l})
		&"chosen_own_empty_lane":
			for l: int in GameState.LANES:
				if (source_lane < 0 or l != GameState.lane_of(source_lane)) and s.players[p].at(l) == null:
					out.append({"player": p, "lane": l})
		&"chosen_enemy_creature", &"chosen_damaged_enemy", &"chosen_frozen_enemy":
			var foe: int = s.opponent(p)
			for l: int in GameState.SPOTS:
				var cr: GameState.CreatureState = s.players[foe].at(l)
				if cr == null or cr.hidden:
					continue
				if who == &"chosen_damaged_enemy" and cr.damage <= 0:
					continue
				if who == &"chosen_frozen_enemy" and not cr.is_frozen():
					continue
				out.append({"player": foe, "lane": l})
		&"chosen_undamaged_creature":
			for q: int in [p, s.opponent(p)]:
				for l: int in GameState.SPOTS:
					var cr: GameState.CreatureState = s.players[q].at(l)
					if cr and cr.damage == 0 and not (q != p and cr.hidden):
						out.append({"player": q, "lane": l})
		&"chosen_discard_creature":
			var d: Array[CardData] = s.players[p].discard
			for i: int in d.size():
				if d[i].kind == CardData.Kind.CREATURE:
					out.append({"discard": i})
	return out


## The targets an effect reaches. `chosen` holds the player's picks for chosen_* whos.
## ctx: "last" = the previous effect's targets (same_target), "damaged" = the creature just
## damaged (after_damage). own_on_land: your creatures on `filter_land`.
static func resolve(s: GameState, p: int, lane: int, who: StringName, chosen: Array[Dictionary], ctx: Dictionary, filter_land: int = -1) -> Array[Dictionary]:
	var foe: int = s.opponent(p)
	var out: Array[Dictionary] = []
	match who:
		&"self", &"lane_creature":
			out.append({"player": p, "lane": lane})
		&"opposing":
			out.append({"player": foe, "lane": GameState.lane_of(lane)})
		&"all_creatures":
			for q: int in [p, foe]:
				for l: int in GameState.SPOTS:
					if s.players[q].at(l):
						out.append({"player": q, "lane": l})
		&"all_enemy_creatures", &"all_own_creatures":
			var q: int = foe if who == &"all_enemy_creatures" else p
			for l: int in GameState.SPOTS:
				if s.players[q].at(l):
					out.append({"player": q, "lane": l})
		&"all_away_creatures":
			# Every creature on both sides that isn't at home (Heatwave).
			for q: int in 2:
				for l: int in GameState.SPOTS:
					if s.players[q].at(l) and not Lands.is_home(s, q, l):
						out.append({"player": q, "lane": l})
		&"own_on_land":
			for l: int in GameState.SPOTS:
				if s.players[p].at(l) and s.players[p].lane(l).land == filter_land:
					out.append({"player": p, "lane": l})
		&"enemy_hero":
			out.append({"hero": foe})
		&"own_hero":
			out.append({"hero": p})
		&"damaged_creature":
			if ctx.has("damaged"):
				out.append(ctx["damaged"])
		&"same_target":
			out.assign(ctx.get("last", []))
		&"other_enemies":
			var last: Array = ctx.get("last", [])
			for l: int in GameState.SPOTS:
				var t := {"player": foe, "lane": l}
				if s.players[foe].at(l) and not t in last:
					out.append(t)
			if not {"hero": foe} in last:
				out.append({"hero": foe})
		_:
			if who in CHOSEN:
				out.assign(chosen)
	return out
