extends Node
## Prints board band and rival head top for candidate seat poses at 1280x720.

func _ready() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	add_child(vp)
	var cam := Camera3D.new()
	vp.add_child(cam)
	cam.make_current()
	var rival := RivalSeat.new(); vp.add_child(rival)
	rival.setup(MatchController.RIVAL_MODEL)
	await get_tree().process_frame
	await get_tree().process_frame
	var cands: Array = [
		[Vector3(0, 8.0, 14.0), Vector3(0, 0.5, -1.5), 58.0],
		[Vector3(0, 8.0, 14.0), Vector3(0, 0.5, -1.8), 58.0],
		[Vector3(0, 8.2, 13.6), Vector3(0, 0.5, -1.8), 58.0],
	]
	for c: Array in cands:
		var pos: Vector3 = c[0]
		var look: Vector3 = c[1]
		cam.global_transform = Transform3D(Basis.looking_at(look - pos, Vector3.UP), pos)
		cam.fov = c[2]
		var ymin: float = 9999.0; var ymax: float = -9999.0; var xmin: float = 9999.0; var xmax: float = -9999.0
		for p: int in 2:
			for l: int in 4:
				for sx: float in [-1.0, 1.0]:
					for sz: float in [-1.0, 1.0]:
						var s: Vector2 = cam.unproject_position(Vector3(BoardLayout.straight().base_centre(l) + sx * Island.WIDTH / 2.0, Island.TOP_Y, Board.STRIP_Z[p] + sz * Island.LENGTH / 2.0))
						ymin = minf(ymin, s.y); ymax = maxf(ymax, s.y); xmin = minf(xmin, s.x); xmax = maxf(xmax, s.x)
		var head: Rect2 = rival.hero_rect(cam)
		var pitch: float = rad_to_deg(atan2(pos.y - look.y, pos.z - look.z))
		print("area %.3f " % ((ymax - ymin) / 720 * (xmax - xmin) / 1280) + "pos%s look%s fov%d pitch%.1f | board y %.2f..%.2f x %.2f..%.2f | head top %.2f bottom %.2f" % [pos, look, c[2], pitch, ymin / 720, ymax / 720, xmin / 1280, xmax / 1280, head.position.y / 720, head.end.y / 720])
	get_tree().quit()
