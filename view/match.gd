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
var busy: bool = false
var creature_views: Array[Array] = [[null, null, null, null], [null, null, null, null]]
var building_views: Array[Array] = [[null, null, null, null], [null, null, null, null]]


func _ready() -> void:
	state = Rules.setup(CardDB.deck(&"blaze_rush"), CardDB.deck(&"deep_freeze"), 1)
	state.first_player = HUMAN
	state.active = HUMAN
	Rules.start_turn(state)
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
	input = InputController.new()
	input.match_ctl = self
	add_child(input)
	hand.card_drag_started.connect(input.on_drag_started)
	hand.card_dropped.connect(input.on_dropped)
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


## Temporary until event playback (Task 12): apply and resync.
func _on_action_requested(a: Action) -> void:
	Rules.apply(state, a)
	sync_all()
	refresh_ui()


## Temporary until the timing bar (Task 13): attack with NORMAL hits, then let the AI play.
func _on_end_turn_pressed() -> void:
	input.cancel()
	Rules.apply(state, Action.begin_attacks(HUMAN))
	for lane: int in Rules.attackers(state):
		Rules.apply(state, Action.attack(HUMAN, lane, Action.Hit.NORMAL, false))
	if state.phase != GameState.Phase.OVER:
		Rules.apply(state, Action.end_turn(HUMAN))
	if state.phase != GameState.Phase.OVER and state.active == AI:
		var ai := AIPlayer.new(AI, AIPlayer.Difficulty.MEDIUM, state.turn)
		var ev: Array[GameEvent] = []
		AIRunner.play_turn(state, ai, AIPlayer.new(HUMAN, AIPlayer.Difficulty.EASY, 0), ev)
	sync_all()
	refresh_ui()


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
				_place_building(p, l, lane.building)
			if lane.creature:
				_place_creature(p, l, lane.creature.card)
	refresh_pieces()


func _place_creature(p: int, l: int, c: CardData) -> CreatureView:
	var v := CreatureView.create(c)
	add_child(v)
	v.position = board.anchor(p, l)
	v.rotation.y = PI * 0.82 if p == HUMAN else 0.0
	creature_views[p][l] = v
	return v


func _place_building(p: int, l: int, c: CardData) -> BuildingView:
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
