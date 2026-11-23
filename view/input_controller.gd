class_name InputController
extends Node
## Turns mouse input (hand drags, island clicks) into Actions. Never mutates state.

signal action_requested(action: Action)

## AIMING: dragging an attack arrow from one of the human's creatures.
enum Mode { IDLE, DRAGGING, TARGETING, AIMING }

## A press that moves less than this is a click (boop), not an attack drag.
const CLICK_SLOP := 14.0

var match_ctl: MatchController
var mode: Mode = Mode.IDLE
var enabled: bool = false

var _hand_index: int = -1
var _lane: int = -1
var _is_boop: bool = false
var _card: CardData
var _targets: Array[Dictionary] = []
var _needed: int = 0
var _aim_lane: int = -1
## While aiming: the enemy lane under the pointer (-1 hero, -2 nothing); its creature's tag grows.
var aim_target: int = -2
var _press_pos := Vector2.ZERO


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
				var merge: bool = Rules.can_merge(_state(), _human(), l, _card)
				match_ctl.board.island(_human(), l).set_highlight(Island.Highlight.MERGE if merge else Island.Highlight.VALID)
				if merge:
					var partner: CardData = _state().players[_human()].lanes[l].creature.card
					match_ctl.toast.show_message("Drop on %s to MERGE" % partner.display_name, 2.0)


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
	if Targeting.chosen_who(Rules.played_form(_state(), _human(), int(hit["lane"]), _card), &"on_play") != &"":
		_begin_card_targets(i, int(hit["lane"]), false)
		return
	_request(Action.play(_human(), i, int(hit["lane"])))


## Cards (and boops) with chosen targets collect them before the action is sent.
func _begin_card_targets(hand_index: int, lane: int, boop: bool) -> void:
	_hand_index = hand_index
	_lane = lane
	_is_boop = boop
	_targets = []
	var form: CardData = _card if boop or lane < 0 else Rules.played_form(_state(), _human(), lane, _card)
	var who: StringName = Targeting.chosen_who(form, &"on_boop" if boop else &"on_play")
	if who == &"":
		_send()
		return
	if who == &"chosen_discard_creature":
		# Regrowth: return the most recently discarded creature (no discard browser yet).
		var options: Array[Dictionary] = Targeting.valid(_state(), _human(), who)
		if not options.is_empty():
			_targets = [options[options.size() - 1]]
		_send()
		return
	var valid: Array[Dictionary] = Targeting.valid(_state(), _human(), who, lane)
	_needed = Targeting.needed(who)
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
			if is_inside_tree():
				get_viewport().set_input_as_handled()
		return
	if not (mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT):
		return
	if mode == Mode.IDLE and try_plate(match_ctl.board.ground_at_screen(match_ctl.rig.camera, mb.position)):
		if is_inside_tree():
			get_viewport().set_input_as_handled()
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
		if Rules.can_attack(_state(), _human(), t["lane"]) and not match_ctl.busy:
			_start_aim(t["lane"], mb.position)
		else:
			request_boop(t["lane"])


# --- Drag to attack ----------------------------------------------------------

## While aiming, motion and the release come here first so HUD panels can't swallow them.
func _input(event: InputEvent) -> void:
	if mode != Mode.AIMING:
		return
	var mm := event as InputEventMouseMotion
	var mb := event as InputEventMouseButton
	var key := event as InputEventKey
	if mm:
		_update_aim(mm.position)
	elif mb and mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed or key and key.pressed and key.keycode == KEY_ESCAPE:
		cancel()
	elif mb and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		_release(mb.position)
	else:
		return
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _start_aim(lane: int, pos: Vector2) -> void:
	mode = Mode.AIMING
	_aim_lane = lane
	_press_pos = pos
	var av: CreatureView = _aim_view()
	if av:
		av.aiming = true
		av.aim_at = av.position + Vector3(0, 0, -1)
	var foe: int = 1 - _human()
	var targets: Array[int] = Rules.attack_targets(_state(), _human(), lane)
	for l: int in 4:
		if _state().players[foe].lanes[l].creature == null:
			continue
		if l in targets:
			var guard: bool = Rules.has_keyword(_state(), foe, l, &"guard")
			match_ctl.board.island(foe, l).set_highlight(Island.Highlight.GUARD if guard else Island.Highlight.TARGET)
		elif match_ctl.creature_views[foe][l]:
			(match_ctl.creature_views[foe][l] as CreatureView).set_dimmed(true)
	_update_aim(pos)


## The aimed creature's view (null if it is gone).
func _aim_view() -> CreatureView:
	if _aim_lane < 0:
		return null
	var v: Variant = match_ctl.creature_views[_human()][_aim_lane]
	return v as CreatureView if is_instance_valid(v) else null


## The arrow starts from wherever the aimed creature stands.
func _aim_origin() -> Vector2:
	var v: CreatureView = _aim_view()
	var at: Vector3 = v.global_position if v else match_ctl.board.anchor(_human(), _aim_lane)
	return match_ctl.rig.camera.unproject_position(at)


## The table between the board's far edge and the rival (world x/z): pointing there means the hero.
static func table_strip() -> Rect2:
	var t: Rect2 = Board.TRAY_RECT
	return Rect2(t.position.x, Room.TABLE_RECT.position.y, t.size.x, t.position.y - Room.TABLE_RECT.position.y)


## The enemy lane under the pointer, -1 for the enemy hero (the rival, their corner panel or the
## table in front of them), -2 for nothing.
func _target_at(pos: Vector2) -> int:
	var cam: Camera3D = match_ctl.rig.camera
	var hit: Dictionary = match_ctl.board.lane_at_screen(cam, pos)
	if not hit.is_empty() and int(hit["player"]) != _human():
		return int(hit["lane"])
	if match_ctl.hud.hero_rect(false).has_point(pos):
		return -1
	if match_ctl.rival and match_ctl.rival.hero_rect(cam).has_point(pos):
		return -1
	var g: Vector3 = match_ctl.board.ground_at_screen(cam, pos)
	if g.is_finite() and table_strip().has_point(Vector2(g.x, g.z)):
		return -1
	return -2


func _update_aim(pos: Vector2) -> void:
	var v: CreatureView = _aim_view()
	if v:
		var g: Vector3 = match_ctl.board.ground_at_screen(match_ctl.rig.camera, pos)
		if g.is_finite():
			v.aim_at = g
	var t: int = _target_at(pos)
	aim_target = t
	var ok: bool = t != -2 and t in Rules.attack_targets(_state(), _human(), _aim_lane)
	match_ctl.attack_arrow.aim(_aim_origin(), pos, ok)


func _release(pos: Vector2) -> void:
	var lane: int = _aim_lane
	var moved: bool = pos.distance_to(_press_pos) > CLICK_SLOP
	cancel()
	if not moved:
		request_boop(lane)
		return
	var t: int = _target_at(pos)
	if t == -2:
		return
	if Rules.validate(_state(), Action.attack(_human(), lane, t)) != "":
		match_ctl.toast.show_message("Can't attack that")
		return
	match_ctl.request_attack(lane, t)


## A click at world point `ground`: if it is on a lit boop plate, press it and boop that lane. True if taken.
func try_plate(ground: Vector3) -> bool:
	if not enabled or mode != Mode.IDLE:
		return false
	var lane: int = match_ctl.board.plate_at(ground)
	if lane < 0 or match_ctl.board.boop_plate(lane).state != BoopPlate.State.LIT:
		return false
	match_ctl.board.boop_plate(lane).press()
	request_boop(lane)
	return true


## True when the human's creature in `lane` can boop right now (targets may still be needed).
func can_boop(lane: int) -> bool:
	if not enabled or mode != Mode.IDLE:
		return false
	var cr: GameState.CreatureState = _state().players[_human()].lanes[lane].creature
	if cr == null or not cr.card.has_effect(&"on_boop") or cr.hushed:
		return false
	var err: String = Rules.validate(_state(), Action.boop(_human(), lane, []))
	return err == "" or err == "Invalid target"


## Boop the human's creature in `lane` (from a creature click or its boop plate).
func request_boop(lane: int) -> void:
	if not enabled:
		return
	var cr: GameState.CreatureState = _state().players[_human()].lanes[lane].creature
	if cr == null:
		return
	if not cr.card.has_effect(&"on_boop") or cr.hushed:
		match_ctl.toast.show_message("%s has no boop ability" % cr.card.display_name)
		return
	var err: String = Rules.validate(_state(), Action.boop(_human(), lane, []))
	if err != "" and err != "Invalid target":
		match_ctl.toast.show_message(err)
		return
	_card = cr.card
	_begin_card_targets(-1, lane, true)


## A creature left the board: if it was the one being aimed with, drop the aim.
func creature_gone(p: int, lane: int) -> void:
	if mode == Mode.AIMING and p == _human() and lane == _aim_lane:
		cancel()


func cancel() -> void:
	var v: CreatureView = _aim_view()
	if v:
		v.aiming = false
	mode = Mode.IDLE
	_targets = []
	_aim_lane = -1
	aim_target = -2
	_clear_highlights()
	match_ctl.hand.cancel_drag()


func _clear_highlights() -> void:
	if match_ctl.attack_arrow:
		match_ctl.attack_arrow.clear()
	for p: int in 2:
		for l: int in 4:
			match_ctl.board.island(p, l).set_highlight(Island.Highlight.OFF)
			var v: CreatureView = match_ctl.creature_views[p][l]
			if is_instance_valid(v):
				v.set_dimmed(false)
