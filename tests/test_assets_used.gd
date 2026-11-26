extends TestCase
## Only assets the game uses are committed (Global Constraints): every monster model, particle
## texture and sweet in the repo is referenced by the code that loads it.


func _files(dir: String, ext: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f: String in DirAccess.get_files_at(dir):
		if f.get_extension() == ext:
			out.append(f)
	return out


func _source(paths: Array[String]) -> String:
	var text: String = ""
	for p: String in paths:
		text += FileAccess.get_file_as_string(p)
	return text


func test_monster_models_used() -> bool:
	var used: Dictionary = {}
	for id: StringName in VisualDB.ids():
		used[VisualDB.model_path(id)] = true
	for f: String in _files("res://assets/monsters/forged", "glb"):
		assert_true(used.has("res://assets/monsters/forged/" + f), "monsters/forged/%s is used" % f)
	# The room's sleeping cat is the one pack model left.
	assert_true(ResourceLoader.exists(Room.CAT), "the room's cat model is there")
	assert_eq(_files("res://assets/monsters/blob", "gltf"), PackedStringArray(["Cat.gltf"]), "only the cat is left in blob/")
	return true


func test_particles_used() -> bool:
	var src: String = _source(["res://view/fx/burst.gd", "res://view/fx/rain.gd", "res://view/board/ambient.gd"])
	for f: String in _files("res://assets/fx/particles", "png"):
		assert_true(("\"%s\"" % f.get_basename()) in src, "particle %s is used" % f)
	return true


func test_candy_used() -> bool:
	var src: String = _source(["res://view/board/lane_dressing.gd"])
	for f: String in _files("res://assets/candy", "glb"):
		assert_true(("candy/%s" % f) in src, "candy/%s is used" % f)
	return true


func test_room_models_used() -> bool:
	var paths: Array[String] = []
	for f: String in DirAccess.get_files_at("res://view/room"):
		if f.get_extension() == "gd":
			paths.append("res://view/room/" + f)
	var src: String = _source(paths)
	for f: String in _files("res://assets/room", "gltf"):
		assert_true(("\"%s\"" % f.get_basename()) in src, "room/%s is used" % f)
	return true
