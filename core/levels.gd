class_name Levels
extends RefCounted
## Creature level-ups (living board spec 6): XP from attacks it survives, +1/+1 per level,
## on_level_up abilities.

const MAX := 3
## Total XP needed for level 2 and level 3.
const XP_FOR: Array[int] = [0, 0, 2, 4]


## Stat bonus from levels (+1 ATK and +1 HP per level above 1).
static func bonus(cr: GameState.CreatureState) -> int:
	return cr.level - 1 if cr else 0


## Gives `amount` XP to the creature in the lane; levels it up (maybe twice) when it gets there.
static func gain_xp(s: GameState, p: int, lane: int, amount: int, ev: Array[GameEvent]) -> void:
	var cr: GameState.CreatureState = s.players[p].lanes[lane].creature
	if cr == null or amount <= 0 or cr.level >= MAX:
		return
	cr.xp += amount
	ev.append(GameEvent.make(&"xp_gained", {"player": p, "lane": lane, "amount": amount, "xp": cr.xp, "level": cr.level}))
	while cr.level < MAX and cr.xp >= XP_FOR[cr.level + 1] and s.phase != GameState.Phase.OVER:
		cr.level += 1
		ev.append(GameEvent.make(&"level_up", {"player": p, "lane": lane, "level": cr.level, "card": cr.card.id}))
		if cr.damage > 0:
			Rules.heal_creature(s, p, lane, 1, ev)
		Effects.run(s, p, lane, cr.card, &"on_level_up", [], ev)
		if s.players[p].lanes[lane].creature != cr:
			return
