class_name SeatView
extends RefCounted
## What one seat sees of a match. The engine keeps the canonical match (`real`, host = player 0);
## the view always shows the local player as player 0. For seat 1 `view` is a mirror that shares the
## same PlayerState objects in swapped order, with the player-index fields flipped; events and actions
## are flipped on the way through. Seat 0 (and every match against the AI) is the identity.

var seat: int = 0
var real: GameState
var view: GameState


func _init(real_state: GameState, local_seat: int) -> void:
	real = real_state
	seat = local_seat
	if seat == 0:
		view = real
	else:
		view = GameState.new()
		view.players.append(real.players[1])
		view.players.append(real.players[0])
		sync()


## Copy the match-wide fields over after every change to `real`.
func sync() -> void:
	if seat == 0:
		return
	view.active = flip(real.active)
	view.first_player = flip(real.first_player)
	view.winner = flip(real.winner)
	view.pending_player = flip(real.pending_player)
	view.field_owner = flip(real.field_owner)
	view.turn = real.turn
	view.phase = real.phase
	view.field = real.field
	view.pending_choice = real.pending_choice


## A player index between the canonical match and this seat's view (the same both ways).
func flip(p: int) -> int:
	if seat == 0 or (p != 0 and p != 1):
		return p
	return 1 - p


func events_to_view(ev: Array[GameEvent]) -> Array[GameEvent]:
	if seat == 0:
		return ev
	var out: Array[GameEvent] = []
	for e: GameEvent in ev:
		var d: Dictionary = e.data.duplicate(true)
		for key: String in ["player", "winner"]:
			if d.has(key):
				d[key] = flip(int(d[key]))
		out.append(GameEvent.make(e.type, d))
	return out


func action_to_real(a: Action) -> Action:
	return _flipped(a)


func action_to_view(a: Action) -> Action:
	return _flipped(a)


func _flipped(a: Action) -> Action:
	var b: Action = Action.from_dict(a.to_dict())
	if seat == 0:
		return b
	b.player = flip(b.player)
	for t: Dictionary in b.targets:
		if t.has("player"):
			t["player"] = flip(int(t["player"]))
	return b
