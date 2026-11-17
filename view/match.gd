class_name MatchController
extends Node3D
## Owns a match: game state, board and (later) HUD, input and playback.

## Human is always player 0 (near the camera).
const HUMAN := 0
const AI := 1
const RIVAL_MODEL := "res://assets/heroes/Barbarian.glb"
## Canvas layer of the HUD (stat bars sit below it, the board hover card above it).
const HUD_LAYER := 2

var state: GameState
var board: Board
var rig: CameraRig
var room: Room
var rival: RivalSeat
var hud: Hud
var hand: Hand
var toast: Toast
var input: InputController
var player: EventPlayer
var timing_bar: TimingBar
var results: Results
var overlay: UnitOverlay
var attack_arrow: AttackArrow
var ai: AIPlayer
var difficulty: AIPlayer.Difficulty = AIPlayer.Difficulty.MEDIUM
const AI_PAUSE := 0.6
## Divides AI pauses (tests speed this up).
var pace: float = 1.0
var busy: bool = false
var creature_views: Array[Array] = [[null, null, null, null], [null, null, null, null]]
var building_views: Array[Array] = [[null, null, null, null], [null, null, null, null]]


func _ready() -> void:
	var seed: int = Session.match_seed()
	difficulty = Session.difficulty
	state = Rules.setup(CardDB.deck(Session.player_deck), CardDB.deck(Session.resolve_ai_deck(seed)), seed)
	ai = AIPlayer.new(AI, difficulty, seed + 7919)
	var opening: Array[GameEvent] = Rules.start_turn(state)
	if "--demo-board" in OS.get_cmdline_user_args():
		var ais: Array[AIPlayer] = [AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 11), AIPlayer.new(1, AIPlayer.Difficulty.MEDIUM, 12)]
		AIRunner.play_match(state, ais, 6)
	rig = CameraRig.new()
	add_child(rig)
	room = Room.new()
	add_child(room)
	room.build(Settings.quality)
	rival = RivalSeat.new()
	add_child(rival)
	rival.setup(RIVAL_MODEL)
	board = Board.new()
	add_child(board)
	var lands: Array[Array] = []
	for p: int in 2:
		var row: Array[int] = []
		for l: GameState.LaneState in state.players[p].lanes:
			row.append(l.land)
		lands.append(row)
	board.build(lands)
	_build_ui()
	Audio.music(GameAudio.MATCH_MUSIC)
	sync_all()
	refresh_ui()
	if "--demo-results" in OS.get_cmdline_user_args():
		results.show_result(true, 9)
		return
	if "--auto-attack" in OS.get_cmdline_user_args():
		_demo_attack()
		return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--sweep-at="):
			rig.hold_sweep(float(arg.substr(11)))
			return
	_begin(opening)


func _begin(opening: Array[GameEvent]) -> void:
	busy = true
	refresh_ui()
	if _wants_sweep():
		await rig.play_sweep()
	else:
		await get_tree().create_timer(0.4).timeout
	await player.play(opening)
	if state.active == AI:
		await _ai_turn()
	busy = false
	refresh_ui()


## The opening sweep around the room, with input locked; a click or key press skips it.
func sweep() -> void:
	var was: bool = busy
	busy = true
	refresh_ui()
	await rig.play_sweep()
	busy = was
	refresh_ui()


## No sweep headless (tests) or for a screenshot unless --sweep-at asks for one.
func _wants_sweep() -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot=") or arg.begins_with("--fps-log="):
			return false
	return true


func _demo_attack() -> void:
	state.turn = 3
	state.active = HUMAN
	state.phase = GameState.Phase.MAIN
	_demo_put(0, 1, &"flarebeak")
	_demo_put(1, 1, &"glacier_tortoise")
	sync_all()
	busy = true
	await perform(Action.attack(HUMAN, 1, 1, Action.Hit.CRIT, false))


func _demo_put(p: int, l: int, id: StringName) -> void:
	var c := GameState.CreatureState.new()
	c.card = CardDB.card(id)
	c.ready = true
	state.players[p].lanes[l].creature = c


func _build_ui() -> void:
	# Stat bars and BOOP buttons sit under the HUD layer.
	var over_layer := CanvasLayer.new()
	over_layer.layer = 1
	add_child(over_layer)
	overlay = UnitOverlay.new()
	over_layer.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layer := CanvasLayer.new()
	layer.layer = HUD_LAYER
	add_child(layer)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud = Hud.new()
	root.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hand = Hand.new()
	root.add_child(hand)
	hand.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	attack_arrow = AttackArrow.new()
	root.add_child(attack_arrow)
	attack_arrow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	toast = Toast.new()
	root.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.offset_top = 64
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	timing_bar = TimingBar.new()
	root.add_child(timing_bar)
	hud.pause_overlay.reparent(root)
	hud.pause_changed.connect(func(_open: bool) -> void: refresh_ui())
	results = Results.new()
	root.add_child(results)
	results.rematch.connect(func() -> void: get_tree().reload_current_scene())
	results.menu.connect(func() -> void: get_tree().change_scene_to_file("res://menus/main_menu.tscn"))
	input = InputController.new()
	input.match_ctl = self
	add_child(input)
	hand.card_drag_started.connect(input.on_drag_started)
	hand.card_dropped.connect(input.on_dropped)
	player = EventPlayer.new()
	player.m = self
	add_child(player)
	input.action_requested.connect(_on_action_requested)
	overlay.setup(self)
	hud.end_turn_pressed.connect(_on_end_turn_pressed)
	hud.menu_requested.connect(func() -> void: get_tree().change_scene_to_file("res://menus/main_menu.tscn"))


## Refresh HUD, hand and input availability from the state.
func refresh_ui() -> void:
	hud.refresh(state, HUMAN)
	var cards: Array[CardData] = state.players[HUMAN].hand
	var playable: Array[bool] = []
	for i: int in cards.size():
		var ok: bool = false
		if cards[i].kind == CardData.Kind.SPELL:
			ok = cards[i].cost <= state.players[HUMAN].magic
		else:
			for l: int in 4:
				if Rules.validate(state, Action.play(HUMAN, i, l)) == "":
					ok = true
					break
		playable.append(ok and state.active == HUMAN)
	hand.show_hand(cards, playable)
	var only_end: bool = state.active == HUMAN and state.phase == GameState.Phase.MAIN and Rules.legal_actions(state).size() == 1
	hud.set_end_turn_pulse(only_end and not busy)
	var paused: bool = hud.is_paused()
	var can_act: bool = state.active == HUMAN and state.phase == GameState.Phase.MAIN and not busy and not paused
	input.enabled = can_act
	hand.enabled = can_act
	hud.set_input_enabled(can_act or paused)
	overlay.refresh(state)


## Validate, apply, and play the resulting events with input locked.
func perform(a: Action) -> void:
	var err: String = Rules.validate(state, a)
	if err != "":
		toast.show_message(err)
		return
	var events: Array[GameEvent] = Rules.apply(state, a)
	await player.play(events)
	if state.phase == GameState.Phase.OVER and not results.visible:
		await get_tree().create_timer(0.6 / pace).timeout
		results.show_result(state.winner == HUMAN, state.turn)


func _on_action_requested(a: Action) -> void:
	busy = true
	refresh_ui()
	await perform(a)
	await _human_dream_up()
	busy = false
	refresh_ui()


## Interim until the Dream Up picker (Rules 2.0 plan Task 15): take the first card offered.
func _human_dream_up() -> void:
	if state.phase == GameState.Phase.CHOOSING and state.pending_player == HUMAN:
		toast.show_message("Dream Up: %s" % state.pending_choice[0].display_name, 1.5)
		await perform(Action.choose(HUMAN, 0))


func _on_end_turn_pressed() -> void:
	if busy or state.active != HUMAN:
		return
	input.cancel()
	busy = true
	refresh_ui()
	await perform(Action.end_turn(HUMAN))
	if state.phase != GameState.Phase.OVER and state.active == AI:
		await _ai_turn()
	busy = false
	refresh_ui()


## Shows who attacks whom for a moment (the rival's attacks).
func show_attack_arrow(p: int, lane: int, target_lane: int) -> void:
	var cam: Camera3D = rig.camera
	var from: Vector2 = cam.unproject_position(board.anchor(p, lane))
	var to: Vector2 = cam.unproject_position(board.anchor(1 - p, target_lane)) if target_lane >= 0 \
		else hud.hero_rect(p == AI).get_center()
	attack_arrow.aim(from, to, true)
	await get_tree().create_timer(0.5 / pace).timeout
	attack_arrow.clear()


## Human attack: the attacker bar sets the hit, the AI may block a creature target.
func request_attack(lane: int, target_lane: int) -> void:
	if busy or state.active != HUMAN:
		return
	var err: String = Rules.validate(state, Action.attack(HUMAN, lane, target_lane))
	if err != "":
		toast.show_message(err)
		return
	input.cancel()
	busy = true
	refresh_ui()
	var hit: Action.Hit = await timing_bar.run_attack()
	var blocked: bool = false
	if target_lane >= 0:
		blocked = ai.roll_block()
		await timing_bar.simulate_block(blocked)
	await perform(Action.attack(HUMAN, lane, target_lane, hit, blocked))
	busy = false
	refresh_ui()


## The AI's whole turn, shown step by step. Ends after the AI's END_TURN (human's turn started).
func _ai_turn() -> void:
	for i: int in AIRunner.MAX_ACTIONS:
		if state.phase == GameState.Phase.OVER or state.active != AI:
			return
		await get_tree().create_timer(AI_PAUSE / pace).timeout
		var a: Action = ai.choose_action(state)
		if a.type == Action.Type.ATTACK:
			await show_attack_arrow(AI, a.lane, a.target_lane)
			a.hit = ai.roll_hit()
			await timing_bar.simulate_attack(a.hit)
			if a.target_lane >= 0:
				a.blocked = await timing_bar.run_block()
		await perform(a)
		if a.type == Action.Type.END_TURN:
			return
	if state.phase == GameState.Phase.CHOOSING:
		await perform(Action.choose(state.pending_player, 0))
	if state.phase != GameState.Phase.OVER and state.active == AI:
		await perform(Action.end_turn(AI))


## If playback and state ever disagree, rebuild from the state.
func verify_views() -> void:
	for p: int in 2:
		for l: int in 4:
			var lane: GameState.LaneState = state.players[p].lanes[l]
			var cv: CreatureView = creature_views[p][l]
			var bv: BuildingView = building_views[p][l]
			var ok_c: bool = (lane.creature == null and cv == null) or (lane.creature != null and cv != null and cv.card == lane.creature.card)
			var ok_b: bool = (lane.building == null and bv == null) or (lane.building != null and bv != null and bv.card == lane.building)
			if not ok_c or not ok_b:
				push_warning("View out of sync at p%d lane %d; resyncing" % [p, l])
				sync_all()
				return


## Rebuild every piece from the state. Used at match start and as a fallback.
func sync_all() -> void:
	for p: int in 2:
		for l: int in 4:
			if creature_views[p][l]:
				(creature_views[p][l] as Node).queue_free()
				creature_views[p][l] = null
			if building_views[p][l]:
				(building_views[p][l] as Node).queue_free()
				building_views[p][l] = null
			var lane: GameState.LaneState = state.players[p].lanes[l]
			if lane.building:
				place_building(p, l, lane.building)
			if lane.creature:
				place_creature(p, l, lane.creature.card)
	refresh_pieces()


func place_creature(p: int, l: int, c: CardData) -> CreatureView:
	var v := CreatureView.create(c)
	add_child(v)
	v.position = board.anchor(p, l)
	v.rotation.y = PI * 0.62 if p == HUMAN else PI * -0.12
	creature_views[p][l] = v
	return v


func place_building(p: int, l: int, c: CardData) -> BuildingView:
	var v := BuildingView.create(c)
	add_child(v)
	var off: Vector3 = BuildingView.OFFSET if p == HUMAN else -BuildingView.OFFSET
	v.position = board.anchor(p, l) - Vector3(0, CreatureView.BASE_Y, 0) + off
	v.rotation.y = 0.0 if p == HUMAN else PI
	building_views[p][l] = v
	return v


func _readiness(p: int, l: int, cr: GameState.CreatureState) -> CreatureView.Readiness:
	if state.phase == GameState.Phase.OVER or cr.is_frozen():
		return CreatureView.Readiness.NONE
	var can_act: bool = Rules.can_attack(state, p, l) or Rules.can_boop(state, p, l)
	if not cr.ready and not can_act:
		return CreatureView.Readiness.SLEEPING
	if p != HUMAN or state.active != HUMAN:
		return CreatureView.Readiness.NONE
	if can_act:
		return CreatureView.Readiness.READY
	return CreatureView.Readiness.SPENT if cr.attacks_used > 0 or cr.booped else CreatureView.Readiness.NONE


## Update freeze and readiness visuals from the state.
func refresh_pieces() -> void:
	for p: int in 2:
		for l: int in 4:
			var v: CreatureView = creature_views[p][l]
			var cr: GameState.CreatureState = state.players[p].lanes[l].creature
			if v and cr:
				v.set_frozen(cr.is_frozen())
				v.set_readiness(_readiness(p, l, cr))
	overlay.refresh(state)
