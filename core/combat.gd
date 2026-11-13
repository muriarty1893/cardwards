class_name Combat
extends RefCounted
## Pure damage maths for attacks (spec 4.4).


static func _apply_hit(attack: int, hit: Action.Hit) -> int:
	match hit:
		Action.Hit.CRIT:
			return ceili(attack * 1.5)
		Action.Hit.GLANCE:
			return maxi(1, attack / 2)
	return attack


## Damage to a defending creature. Order: hit multiplier, Ice Wall, block.
static func attack_damage(attack: int, hit: Action.Hit, blocked: bool, ice_wall: bool) -> int:
	if attack <= 0:
		return 0
	var d: int = _apply_hit(attack, hit)
	if ice_wall:
		d = maxi(1, d - 1)
	if blocked:
		d = d / 2
	return d


static func hero_damage(attack: int, hit: Action.Hit) -> int:
	if attack <= 0:
		return 0
	return _apply_hit(attack, hit)
