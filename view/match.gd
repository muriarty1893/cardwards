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
## The field spell's weather, light and table prop.
var field_fx: FieldFx
## Creatures placed so far (seeds each one's wandering).
var _placed: int = 0
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
## Creature houses (decoration), kept in step with the creatures by _sync_houses.
var house_views: Array[Array] = [[null, null, null, null], [null, null, null, null]]
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
	field_fx = FieldFx.new()
	field_fx.name = "FieldFx"
	add_child(field_fx)
	field_fx.setup(room, Settings.quality)
	rival = RivalSeat.new()
	add_child(rival)
	rival.setup(RIVAL_MODEL)
	rival.set_hand_count(state.players[AI].hand.size(), false)
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
	if "--full-board" in OS.get_cmdline_user_args():
		_demo_full_board()
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--demo-living"):
			_demo_living(arg.substr(14) if arg.length() > 14 else "volcano")
			for act: String in OS.get_cmdline_user_args():
				if act.begins_with("--demo-act="):
					_demo_act(act.substr(11))
			return
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--sweep-at="):
			rig.hold_sweep(float(arg.substr(11)))
			return
	_begin(opening)


## Where the rival's card fan is on screen: cards it draws fly there, cards it plays leave it.
func rival_hand_screen() -> Vector2:
	if rival and rig and rig.camera and rig.camera.is_inside_tree():
		return rig.camera.unproject_position(rival.hand_point())
	return hud.hero_screen_pos(false)


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


## The ground cover leans away from every creature on the board.
func _process(_delta: float) -> void:
	if board == null:
		return
	var pts := PackedVector3Array()
	for p: int in 2:
		for l: int in 4:
			var v: Variant = creature_views[p][l]
			if is_instance_valid(v):
				pts.append((v as Node3D).global_position)
	board.set_bend_points(pts)


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


## Dev: a ready creature in all 8 half-lanes (for frame-rate checks and screenshots).
func _demo_full_board() -> void:
	var ids: Array[StringName] = [&"mossback", &"flarebeak", &"gumdrop", &"iceling", &"glacier_tortoise", &"lollibat", &"cinderpup", &"sporeling"]
	for p: int in 2:
		for l: int in 4:
			_demo_put(p, l, ids[p * 4 + l])
	sync_all()


## Dev view of the living board (screenshots): claimed lands, a field (--demo-living=<field id>),
## levelled creatures, buildings and armour.
func _demo_living(field_id: String) -> void:
	var lands: Array[Array] = [[0, 1, 4, 3], [2, 1, 1, 4]]
	var ids: Array[StringName] = [&"sporeling", &"flarebeak", &"gumdrop", &"snowmite", &"taffy_snail", &"cinderpup", &"magmaw", &"iceling"]
	var levels: Array[int] = [1, 3, 1, 2, 1, 2, 1, 1]
	for p: int in 2:
		state.players[p].armour = [5, 3][p]
		for l: int in 4:
			state.players[p].lanes[l].land = lands[p][l]
			_demo_put(p, l, ids[p * 4 + l])
			state.players[p].lanes[l].creature.level = levels[p * 4 + l]
	state.players[0].lanes[1].building = CardDB.card(&"kiln_tower")
	state.players[1].lanes[0].building = CardDB.card(&"sugar_shack")
	if field_id != "none":
		state.field = CardDB.card(StringName(field_id))
		state.field_owner = 1
	sync_all()
	refresh_ui()


## One scripted action in the living demo, for mid-animation screenshots: melt (fireball on
## the rival's Frostpeak lane... made Frostpeak first), claim (a creature into Meadow), level
## (an attack that levels up), field (Snowstorm replaces the field).
func _demo_act(act: String) -> void:
	busy = true
	state.active = HUMAN
	state.players[HUMAN].magic = 9
	await get_tree().create_timer(0.8).timeout
	match act:
		"melt":
			state.players[1].lanes[3].land = CardData.Land.FROST
			board.change_land(1, 3, CardData.Land.FROST, Vector3.INF, false)
			await perform(Action.play(HUMAN, Fx_give(&"fireball"), -1, [{"player": 1, "lane": 3}]))
		"claim":
			state.players[0].lanes[2].creature = null
			sync_all()
			await perform(Action.play(HUMAN, Fx_give(&"cinderpup"), 2))
		"level":
			state.players[0].lanes[3].creature.xp = 3
			state.players[0].lanes[3].creature.attacks_used = 0
			await perform(Action.attack(HUMAN, 3, 3, Action.Hit.NORMAL, false))
		"field":
			await perform(Action.play(HUMAN, Fx_give(&"snowstorm"), -1))


func Fx_give(id: StringName) -> int:
	state.players[HUMAN].hand.append(CardDB.card(id))
	return state.players[HUMAN].hand.size() - 1


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
			if board.island(p, l).land != lane.land:
				push_warning("Land out of sync at p%d lane %d; resyncing" % [p, l])
				board.change_land(p, l, lane.land, Vector3.INF, false)
			if not ok_c or not ok_b:
				push_warning("View out of sync at p%d lane %d; resyncing" % [p, l])
				sync_all()
				return


## Rebuild every piece (and the lands and field) from the state. Used at match start and as a
## fallback.
func sync_all() -> void:
	board.set_field(state.field.land if state.field else -1, false)
	if field_fx:
		field_fx.set_field(state.field.land if state.field else -1, false)
	for p: int in 2:
		for l: int in 4:
			if board.island(p, l).land != state.players[p].lanes[l].land:
				board.change_land(p, l, state.players[p].lanes[l].land, Vector3.INF, false)
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


## Places a creature view in its half-lane (at `drop`, clamped into the roam zone, if given) and
## starts it wandering.
func place_creature(p: int, l: int, c: CardData, drop: Vector3 = Vector3.INF) -> CreatureView:
	var v := CreatureView.create(c)
	add_child(v)
	var zone: Rect2 = board.roam_rect(p, l)
	if CreatureHouse.wants_house(c.id):
		# Keep clear of the house on the lane's right-hand side.
		zone.size.x -= Board.HOUSE_CLEAR
	var at: Vector3 = board.anchor(p, l)
	if drop.is_finite():
		at = Vector3(clampf(drop.x, zone.position.x, zone.end.x), Board.CREATURE_Y, clampf(drop.z, zone.position.y, zone.end.y))
	v.position = at
	var heading: float = rest_heading(p)
	v.rotation.y = heading
	_placed += 1
	v.wanderer.rest_heading = heading
	v.wanderer.step_every = Wanderer.STEP_EVERY * (2.0 if Settings.quality == GameSettings.Quality.LOW else 1.0)
	v.wanderer.footstep = func(pos: Vector3) -> void: _footstep(v, pos)
	v.wanderer.neighbours = func() -> Array: return creature_views[p]
	v.wanderer.setup(v, zone, hash([p, l, String(c.id), _placed]))
	creature_views[p][l] = v
	return v


## Where a creature looks while standing: towards the enemy side, turned to the camera.
static func rest_heading(p: int) -> float:
	return PI * 0.62 if p == HUMAN else PI * -0.12


## A small puff of the land the creature is walking on.
func _footstep(v: CreatureView, pos: Vector3) -> void:
	for p: int in 2:
		var l: int = creature_views[p].find(v)
		if l >= 0:
			Burst.spawn(self, EventPlayer.LAND_BURSTS[state.players[p].lanes[l].land], pos, Color.WHITE, 0.3)
			return


func place_building(p: int, l: int, c: CardData) -> BuildingView:
	var v := BuildingView.create(c)
	add_child(v)
	var bp: Vector3 = board.building_point(p, l)
	v.position = Vector3(bp.x, 0.0, bp.z)
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
				if not v.busy:
					v.set_level(cr.level)
				v.set_home(Lands.home(state, p, l))
				v.set_weather(state.field.land if state.field else -1)
	_sync_houses()
	overlay.refresh(state)


## Every creature that brings a house has one in its lane; houses whose creature is gone (or
## moved) sink away.
func _sync_houses() -> void:
	for p: int in 2:
		for l: int in 4:
			var cv: Variant = creature_views[p][l]
			var v: CreatureView = cv as CreatureView if is_instance_valid(cv) else null
			var hv: Variant = house_views[p][l]
			var h: CreatureHouse = hv as CreatureHouse if is_instance_valid(hv) else null
			var want: bool = v != null and CreatureHouse.wants_house(v.card.id)
			if h and (not want or h.resident != v):
				if is_instance_valid(h.resident) and (h.resident as CreatureView).house == h:
					(h.resident as CreatureView).exit_house(true)
					(h.resident as CreatureView).house = null
				h.sink_away()
				h = null
			house_views[p][l] = h
			if want and h == null:
				h = CreatureHouse.create(v.card.land, 1.0)
				add_child(h)
				h.position = board.house_point(p, l)
				h.resident = v
				v.house = h
				h.pop_in()
				house_views[p][l] = h
