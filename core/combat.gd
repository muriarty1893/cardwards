class_name Combat
extends RefCounted
## Attacks (Rules 2.0 spec 3.4): damage maths and resolving one attack with hit-back.


static func _apply_hit(attack: int, hit: Action.Hit) -> int:
	match hit:
		Action.Hit.CRIT:
			return ceili(attack * 1.5)
		Action.Hit.GLANCE:
			return maxi(1, attack / 2)
	return attack


## Damage to a defending creature. Order: hit multiplier, Ice Wall reduction (min 1), block.
static func attack_damage(attack: int, hit: Action.Hit, blocked: bool, reduction: int) -> int:
	if attack <= 0:
		return 0
	var d: int = _apply_hit(attack, hit)
	if reduction > 0:
		d = maxi(1, d - reduction)
	if blocked:
		d = d / 2
	return d


static func hero_damage(attack: int, hit: Action.Hit) -> int:
	if attack <= 0:
		return 0
	return _apply_hit(attack, hit)


## The defender's damage back to its attacker. The timing bars never change it.
static func hit_back_damage(atk: int, reduction: int) -> int:
	if atk <= 0:
		return 0
	return maxi(1, atk - reduction) if reduction > 0 else atk


## Resolves a validated ATTACK: reveal, count the attack, deal both damages, deaths, then XP.
static func resolve(s: GameState, a: Action, ev: Array[GameEvent]) -> void:
	var p: int = a.player
	var foe: int = s.opponent(p)
	var cr: GameState.CreatureState = s.players[p].lanes[a.lane].creature
	Rules.reveal(s, p, a.lane, ev)
	cr.attacks_used += 1
	var target_cr: GameState.CreatureState = s.players[foe].lanes[a.target_lane].creature if a.target_lane >= 0 else null
	ev.append(GameEvent.make(&"attack", {"player": p, "lane": a.lane, "target_lane": a.target_lane, "hit": int(a.hit),
		"card": cr.card.id, "target_card": target_cr.card.id if target_cr else &""}))
	var atk: int = Rules.effective_attack(s, p, a.lane)
	var src: Dictionary = {"player": p, "lane": a.lane, "kind": &"attack"}
	var defender: GameState.CreatureState = s.players[foe].lanes[a.target_lane].creature if a.target_lane >= 0 else null
	if a.target_lane < 0:
		Rules.damage_hero(s, foe, hero_damage(atk + Tribes.hero_attack_bonus(s, p, a.lane), a.hit), ev, src)
	else:
		# Both amounts are fixed before either lands: the hits are simultaneous.
		var dealt: int = attack_damage(atk, a.hit, a.blocked, Rules.damage_reduction(s, foe, a.target_lane))
		var back: int = hit_back_damage(Rules.effective_attack(s, foe, a.target_lane), Rules.damage_reduction(s, p, a.lane))
		Rules.damage_creature(s, foe, a.target_lane, dealt, src, ev, a.hit, a.blocked)
		if s.players[p].lanes[a.lane].creature == cr and s.players[foe].lanes[a.target_lane].creature:
			Rules.damage_creature(s, p, a.lane, back, {"player": foe, "lane": a.target_lane, "kind": &"hit_back"}, ev)
	Rules.resolve_deaths(s, ev)
	# Level-up XP (living board spec 6): +1 for surviving the attack, +1 for destroying the defender.
	if s.phase != GameState.Phase.OVER and s.players[p].lanes[a.lane].creature == cr:
		var killed: bool = defender != null and s.players[foe].lanes[a.target_lane].creature != defender
		Levels.gain_xp(s, p, a.lane, 2 if killed else 1, ev)
		Rules.resolve_deaths(s, ev)
