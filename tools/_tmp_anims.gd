extends SceneTree
func _initialize() -> void:
	for f: String in DirAccess.get_files_at("res://assets/monsters/extra"):
		if f.ends_with(".import") or f.ends_with(".gd") or f.ends_with(".uid") or f.ends_with(".png") or f.ends_with(".bin"):
			continue
		var ps := load("res://assets/monsters/extra/" + f) as PackedScene
		if ps == null:
			print("A %s: LOAD FAIL" % f); continue
		var n: Node = ps.instantiate()
		var ap := n.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var aabb := AABB()
		for mi: Node in n.find_children("*", "MeshInstance3D", true, false):
			aabb = aabb.merge((mi as MeshInstance3D).get_aabb())
		print("A %s: %s size=%s" % [f, ap.get_animation_list() if ap else "NO AP", aabb.size])
		n.free()
	quit()
