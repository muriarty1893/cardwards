class_name MatchController
extends Node3D
## Owns a match: game state, board and (later) HUD, input and playback.

## Human is always player 0 (near the camera).
const HUMAN := 0
const AI := 1

var state: GameState
var board: Board
var rig: CameraRig
var hud: Hud
var hand: Hand
var toast: Toast
var input: InputController
var player: EventPlayer
var timing_bar: TimingBar
var ai: AIPlayer
var difficulty: AIPlayer.Difficulty = AIPlayer.Difficulty.MEDIUM
const AI_PAUSE := 0.6
## Divides AI pauses (tests speed this up).
var pace: float = 1.0
var busy: bool = false
var creature_views: Array[Array] = [[null, null, null, null], [null, null, null, null]]
var building_views: Array[Array] = [[null, null, null, null], [null, null, null, null]]


func _ready() -> void:
	state = Rules.setup(CardDB.deck(&"blaze_rush"), CardDB.deck(&"deep_freeze"), 1)
	ai = AIPlayer.new(AI, difficulty, 1 + 7919)
	var opening: Array[GameEvent] = Rules.start_turn(state)
	if "--demo-board" in OS.get_cmdline_user_args():
		var ais: Array[AIPlayer] = [AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 11), AIPlayer.new(1, AIPlayer.Difficulty.MEDIUM, 12)]
		AIRunner.play_match(state, ais, 6)
	rig = CameraRig.new()
	add_child(rig)
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
	sync_all()
	refresh_ui()
	if "--auto-attack" in OS.get_cmdline_user_args():
		_demo_attack()
		return
	_begin(opening)


func _begin(opening: Array[GameEvent]) -> void:
	busy = true
	refresh_ui()
	await get_tree().create_timer(0.4).timeout
	await player.play(opening)
	if state.active == AI:
		await _ai_turn()
	busy = false
	refresh_ui()


func _demo_attack() -> void:
	state.turn = 3
	_demo_put(0, 1, &"flarebeak")
	_demo_put(1, 1, &"glacier_tortoise")
	sync_all()
	busy = true
	await perform(Action.begin_attacks(HUMAN))
	await perform(Action.attack(HUMAN, 1, Action.Hit.CRIT, false))


func _demo_put(p: int, l: int, id: StringName) -> void:
	var c := GameState.CreatureState.new()
	c.card = CardDB.card(id)
	state.players[p].lanes[l].creature = c


func _build_ui() -> void:
	var layer := CanvasLayer.new()
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
	toast = Toast.new()
	root.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.offset_top = 80
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	timing_bar = TimingBar.new()
	root.add_child(timing_bar)
	input = InputController.new()
	input.match_ctl = self
	add_child(input)
	hand.card_drag_started.connect(input.on_drag_started)
	hand.card_dropped.connect(input.on_dropped)
	player = EventPlayer.new()
	player.m = self
	add_child(player)
	input.action_requested.connect(_on_action_requested)
	hud.end_turn_pressed.connect(_on_end_turn_pressed)


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
	var can_act: bool = state.active == HUMAN and state.phase == GameState.Phase.MAIN and not busy
	input.enabled = can_act
	hand.enabled = can_act
	hud.set_input_enabled(can_act)


## Validate, apply, and play the resulting events with input locked.
func perform(a: Action) -> void:
	var err: String = Rules.validate(state, a)
	if err != "":
		toast.show_message(err)
		return
	var events: Array[GameEvent] = Rules.apply(state, a)
	await player.play(events)


func _on_action_requested(a: Action) -> void:
	busy = true
	refresh_ui()
	await perform(a)
	busy = false
	refresh_ui()


func _on_end_turn_pressed() -> void:
	if busy or state.active != HUMAN:
		return
	input.cancel()
	busy = true
	refresh_ui()
	await perform(Action.begin_attacks(HUMAN))
	for lane: int in Rules.attackers(state):
		if state.phase == GameState.Phase.OVER:
			break
		var hit: Action.Hit = await timing_bar.run_attack()
		var blocked: bool = false
		if Rules.has_defender(state, lane):
			blocked = ai.roll_block()
			await timing_bar.simulate_block(blocked)
		await perform(Action.attack(HUMAN, lane, hit, blocked))
	if state.phase != GameState.Phase.OVER:
		await perform(Action.end_turn(HUMAN))
	if state.phase != GameState.Phase.OVER and state.active == AI:
		await _ai_turn()
	busy = false
	refresh_ui()


## The AI's whole turn, shown step by step. Ends after the AI's END_TURN (human's turn started).
func _ai_turn() -> void:
	for i: int in AIRunner.MAX_MAIN_ACTIONS:
		if state.phase != GameState.Phase.MAIN:
			break
		await get_tree().create_timer(AI_PAUSE / pace).timeout
		var a: Action = ai.choose_main_action(state)
		await perform(a)
		if a.type == Action.Type.BEGIN_ATTACKS:
			break
	if state.phase == GameState.Phase.MAIN:
		await perform(Action.begin_attacks(AI))
	for lane: int in Rules.attackers(state):
		if state.phase == GameState.Phase.OVER:
			return
		var hit: Action.Hit = ai.roll_hit()
		await timing_bar.simulate_attack(hit)
		var blocked: bool = false
		if Rules.has_defender(state, lane):
			blocked = await timing_bar.run_block()
		await perform(Action.attack(AI, lane, hit, blocked))
	if state.phase == GameState.Phase.ATTACK:
		await get_tree().create_timer(AI_PAUSE * 0.5 / pace).timeout
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
	v.rotation.y = PI * 0.82 if p == HUMAN else 0.0
	creature_views[p][l] = v
	return v


func place_building(p: int, l: int, c: CardData) -> BuildingView:
	var v := BuildingView.create(c)
	add_child(v)
	var off: Vector3 = BuildingView.OFFSET if p == HUMAN else -BuildingView.OFFSET
	v.position = board.anchor(p, l) - Vector3(0, CreatureView.BASE_Y, 0) + off
	building_views[p][l] = v
	return v


## Update stat badges and freeze visuals from the state.
func refresh_pieces() -> void:
	for p: int in 2:
		for l: int in 4:
			var v: CreatureView = creature_views[p][l]
			var cr: GameState.CreatureState = state.players[p].lanes[l].creature
			if v and cr:
				var max_hp: int = Rules.effective_max_hp(state, p, l)
				v.set_stats(Rules.effective_attack(state, p, l), max_hp - cr.damage, max_hp)
				v.set_frozen(cr.is_frozen())
