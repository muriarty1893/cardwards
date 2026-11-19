class_name RivalDriver
extends RefCounted
## Who plays the other side of a match, and how the local player's moves reach the game.
## AiRival: the computer, moves apply at once. OnlineRival: a person, moves go through the server.

var m: MatchController


## After the opening has played. (The base methods are never used; their awaits only mark them as
## coroutines so callers can await any driver.)
func begin() -> void:
	await m.get_tree().process_frame


## A local move (view space) other than an attack; returns once it has played.
func submit(_a: Action) -> void:
	await m.get_tree().process_frame


## A local attack after the attack bar gave `hit`; returns once it has played.
func attack(_lane: int, _target_lane: int, _hit: Action.Hit) -> void:
	await m.get_tree().process_frame


## True while the driver is playing something that must keep the local player's input locked.
func blocks_input() -> bool:
	return false


func process(_delta: float) -> void:
	pass


func menu_changed(_open: bool) -> void:
	pass


## The local player leaves the match (menu).
func leave() -> void:
	pass


func rival_name() -> String:
	return "Rival"


func is_online() -> bool:
	return false
