extends Node3D
## Dev view of the room, board and seated rival without any UI, for tuning by screenshot:
##   godot --path . res://tools/room_preview.tscn -- --shot=<png> [--cam=x,y,z] [--look=x,y,z] [--fov=f]
##   [--rival=<reaction: play_card|cheer|flinch|win|lose|think>]
##   [--variants=<land 0-3>] lays that land's 3 looks on lanes 0-2 of both sides (lane 3: look 0, other corner)
##   [--layout-seed=<n>] river layout seed (default 7)

var _cam: Camera3D


static func _vec(s: String) -> Vector3:
	var p: PackedStringArray = s.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))


func _ready() -> void:
	var room := Room.new()
	add_child(room)
	room.build(Settings.quality)
	var rival := RivalSeat.new()
	add_child(rival)
	rival.setup(MatchController.RIVAL_MODEL)
	var board := Board.new()
	add_child(board)
	var a: Array[int] = [0, 1, 2, 3]
	var b: Array[int] = [3, 2, 1, 0]
	var seed: int = 7
	var variants: int = -1
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--layout-seed="):
			seed = int(arg.substr(14))
		elif arg.begins_with("--variants="):
			variants = int(arg.substr(11))
	board.build([a, b], BoardLayout.make(seed))
	board.reveal_split(false)
	if variants >= 0:
		for p: int in 2:
			for l: int in 4:
				board.island(p, l).set_look(variants, l % 3, (l + p) % 2 if l < 3 else 1 - p)
	var cam_pos := Vector3(0, 9, 13.5)
	var look := Vector3(0, 0.5, -1.5)
	_cam = Camera3D.new()
	_cam.fov = 42.0
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--cam="):
			cam_pos = _vec(arg.substr(6))
		elif arg.begins_with("--look="):
			look = _vec(arg.substr(7))
		elif arg.begins_with("--fov="):
			_cam.fov = float(arg.substr(6))
		elif arg.begins_with("--rival="):
			rival.call(arg.substr(8)) if arg.substr(8) != "think" else rival.think(true)
	add_child(_cam)
	_cam.look_at_from_position(cam_pos, look)
	_cam.make_current()
	Outline.attach(_cam)
