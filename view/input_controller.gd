class_name InputController
extends Node
## Turns mouse input (hand drags, island clicks) into Actions. Never mutates state.

signal action_requested(action: Action)

enum Mode { IDLE, DRAGGING, TARGETING }

var match_ctl: MatchController
var mode: Mode = Mode.IDLE
var enabled: bool = false

var _hand_index: int = -1
var _lane: int = -1
var _is_boop: bool = false
var _card: CardData
var _targets: Array[Dictionary] = []
var _needed: int = 0


func _state() -> GameState:
	return match_ctl.state


func _human() -> int:
	return MatchController.HUMAN


# --- Hand drag ---------------------------------------------------------------

func on_drag_started(i: int) -> void:
	if not enabled:
		match_ctl.hand.cancel_drag()
		return
	mode = Mode.DRAGGING
	_hand_index = i
	_card = _state().players[_human()].hand[i]
	_clear_highlights()
	if _card.kind != CardData.Kind.SPELL:
		for l: int in 4:
			if Rules.validate(_state(), Action.play(_human(), i, l)) == "":
				match_ctl.board.island(_human(), l).set_highlight(Island.Highlight.VALID)


func on_dropped(i: int, screen_pos: Vector2) -> void:
	if mode != Mode.DRAGGING:
		return
	_clear_highlights()
	mode = Mode.IDLE
	var hand_top: float = match_ctl.hand.cards_rect().position.y
	if screen_pos.y > hand_top - 10.0:
		match_ctl.hand.cancel_drag()
		return
	if _card.kind == CardData.Kind.SPELL:
		_begin_card_targets(i, -1, false)
		return
	var hit: Dictionary = match_ctl.board.lane_at_screen(match_ctl.rig.camera, screen_pos)
	if hit.is_empty() or int(hit["player"]) != _human():
		match_ctl.hand.cancel_drag()
		return
	_request(Action.play(_human(), i, int(hit["lane"])))


## Spells (and Lollibat's boop) may need targets before the action is sent.
func _begin_card_targets(hand_index: int, lane: int, boop: bool) -> void:
	_hand_index = hand_index
	_lane = lane
	_is_boop = boop
	_targets = []
	if _card.target == &"none":
		_send()
		return
	if _card.target == &"discard_creature":
		# Regrowth: return the most recently discarded creature (no discard browser in v1).
		var options: Array[Dictionary] = Rules.valid_targets(_state(), _human(), _card)
		if not options.is_empty():
			_targets = [options[options.size() - 1]]
		_send()
		return
	var valid: Array[Dictionary] = Rules.valid_targets(_state(), _human(), _card, lane)
	_needed = 2 if _card.target == &"own_two_creatures" else 1
	if valid.size() < _needed:
		_send()  # let validate produce "No valid target"
		return
	mode = Mode.TARGETING
	for t: Dictionary in valid:
		match_ctl.board.island(int(t["player"]), int(t["lane"])).set_highlight(Island.Highlight.TARGET)
	match_ctl.toast.show_message("Choose a target" if _needed == 1 else "Choose two creatures", 2.5)


func _send() -> void:
	mode = Mode.IDLE
	_clear_highlights()
	if _is_boop:
		_request(Action.boop(_human(), _lane, _targets))
	else:
		_request(Action.play(_human(), _hand_index, _lane, _targets))


func _request(a: Action) -> void:
	var err: String = Rules.validate(_state(), a)
	if err != "":
		match_ctl.toast.show_message(err)
		match_ctl.hand.cancel_drag()
		return
	action_requested.emit(a)


# --- Board clicks ------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	var key := event as InputEventKey
	var mb := event as InputEventMouseButton
	if (key and key.pressed and key.keycode == KEY_ESCAPE) or (mb and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT):
		if mode == Mode.TARGETING:
			cancel()
			match_ctl.toast.show_message("Cancelled", 0.8)
		return
	if not (mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT):
		return
	var hit: Dictionary = match_ctl.board.lane_at_screen(match_ctl.rig.camera, mb.position)
	if hit.is_empty():
		return
	var t: Dictionary = {"player": int(hit["player"]), "lane": int(hit["lane"])}
	if mode == Mode.TARGETING:
		if t in _targets:
			return
		_targets.append(t)
		match_ctl.board.island(t["player"], t["lane"]).set_highlight(Island.Highlight.VALID)
		if _targets.size() >= _needed:
			_send()
		return
	if mode == Mode.IDLE and t["player"] == _human():
		request_boop(t["lane"])


## True when the human's creature in `lane` can boop right now (targets may still be needed).
func can_boop(lane: int) -> bool:
	if not enabled or mode != Mode.IDLE:
		return false
	var cr: GameState.CreatureState = _state().players[_human()].lanes[lane].creature
	if cr == null or cr.card.trigger != &"on_boop":
		return false
	var err: String = Rules.validate(_state(), Action.boop(_human(), lane, []))
	return err == "" or err == "Invalid target"


## Boop the human's creature in `lane` (from a creature click or its BOOP button).
func request_boop(lane: int) -> void:
	if not enabled:
		return
	var cr: GameState.CreatureState = _state().players[_human()].lanes[lane].creature
	if cr == null:
		return
	if cr.card.trigger != &"on_boop":
		match_ctl.toast.show_message("%s has no boop ability" % cr.card.display_name)
		return
	var err: String = Rules.validate(_state(), Action.boop(_human(), lane, []))
	if err != "" and err != "Invalid target":
		match_ctl.toast.show_message(err)
		return
	_card = cr.card
	_begin_card_targets(-1, lane, true)


func cancel() -> void:
	mode = Mode.IDLE
	_targets = []
	_clear_highlights()
	match_ctl.hand.cancel_drag()


func _clear_highlights() -> void:
	for p: int in 2:
		for l: int in 4:
			match_ctl.board.island(p, l).set_highlight(Island.Highlight.OFF)
