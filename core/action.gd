class_name Action
extends RefCounted
## Something a player (human or AI) wants to do. Plain data so it can go over a network.

enum Type { PLAY_CARD, BOOP, ATTACK, CHOOSE, END_TURN }
enum Hit { NORMAL, CRIT, GLANCE }

var type: Type = Type.END_TURN
var player: int = 0
var hand_index: int = -1
var lane: int = -1
## Each target: {"player": int, "lane": int} or {"discard": int}
var targets: Array[Dictionary] = []
var hit: Hit = Hit.NORMAL
var blocked: bool = false
## ATTACK: the enemy lane attacked, or -1 for the enemy hero.
var target_lane: int = -1
## CHOOSE: index into GameState.pending_choice.
var choice: int = -1


static func _make(t: Type, p: int) -> Action:
	var a := Action.new()
	a.type = t
	a.player = p
	return a


static func play(p: int, hand_index: int, lane: int, targets: Array[Dictionary] = []) -> Action:
	var a := _make(Type.PLAY_CARD, p)
	a.hand_index = hand_index
	a.lane = lane
	a.targets = targets.duplicate()
	return a


static func boop(p: int, lane: int, targets: Array[Dictionary] = []) -> Action:
	var a := _make(Type.BOOP, p)
	a.lane = lane
	a.targets = targets.duplicate()
	return a


## Creature in `lane` attacks the enemy creature in `target_lane`, or the enemy hero (-1).
static func attack(p: int, lane: int, target_lane: int, hit: Hit = Hit.NORMAL, blocked: bool = false) -> Action:
	var a := _make(Type.ATTACK, p)
	a.lane = lane
	a.target_lane = target_lane
	a.hit = hit
	a.blocked = blocked
	return a


static func end_turn(p: int) -> Action:
	return _make(Type.END_TURN, p)


static func choose(p: int, index: int) -> Action:
	var a := _make(Type.CHOOSE, p)
	a.choice = index
	return a


func to_dict() -> Dictionary:
	return {
		"type": int(type), "player": player, "hand_index": hand_index, "lane": lane,
		"targets": targets.duplicate(true), "hit": int(hit), "blocked": blocked, "choice": choice,
		"target_lane": target_lane,
	}


static func from_dict(d: Dictionary) -> Action:
	var a := Action.new()
	a.type = int(d.get("type", 0)) as Type
	a.player = int(d.get("player", 0))
	a.hand_index = int(d.get("hand_index", -1))
	a.lane = int(d.get("lane", -1))
	var ts: Array = d.get("targets", [])
	for t: Variant in ts:
		var td: Dictionary = {}
		for k: Variant in (t as Dictionary):
			td[k] = int((t as Dictionary)[k])
		a.targets.append(td)
	a.hit = int(d.get("hit", 0)) as Hit
	a.blocked = bool(d.get("blocked", false))
	a.choice = int(d.get("choice", -1))
	a.target_lane = int(d.get("target_lane", -1))
	return a


func _to_string() -> String:
	return str(to_dict())
