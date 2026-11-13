class_name MatchController
extends Node3D
## Owns a match: game state, board and (later) HUD, input and playback.

## Human is always player 0 (near the camera).
const HUMAN := 0
const AI := 1

var state: GameState
var board: Board
var rig: CameraRig
var creature_views: Array[Array] = [[null, null, null, null], [null, null, null, null]]
var building_views: Array[Array] = [[null, null, null, null], [null, null, null, null]]


func _ready() -> void:
	state = Rules.setup(CardDB.deck(&"blaze_rush"), CardDB.deck(&"deep_freeze"), 1)
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
	sync_all()


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
