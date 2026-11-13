class_name MatchController
extends Node3D
## Owns a match: game state, board and (later) HUD, input and playback.

var state: GameState
var board: Board
var rig: CameraRig


func _ready() -> void:
	state = Rules.setup(CardDB.deck(&"blaze_rush"), CardDB.deck(&"deep_freeze"), 1)
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
