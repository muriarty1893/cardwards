extends TestCase
## Free creature models: every creature has a model of its own (no recoloured copies), every model loads with its
## textures, and the cute-pack models play under the animation names CreatureView uses.

## Cute-pack models with the full animation set (Mushroom has only an idle, Bat three).
const FULL_CUTE: Array[String] = ["Alien", "Alien_Tall", "Demon", "Ghost", "Panda", "Skull", "Tree", "Yeti"]


static func _creature_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for c: CardData in CardDB.all_cards():
		if c.is_creature() and VisualDB.merge_pair(c.id).is_empty():
			out.append(c.id)
	return out


func test_every_creature_has_its_own_model() -> bool:
	var owner: Dictionary = {}
	for id: StringName in _creature_ids():
		var path: String = VisualDB.model_path(id)
		assert_true(path != "", "%s has a model" % id)
		assert_true(not owner.has(path), "%s has its own model (%s is also %s's)" % [id, path, owner.get(path, "")])
		owner[path] = id
	return true


func test_models_load_with_idle() -> bool:
	for id: StringName in _creature_ids():
		var path: String = VisualDB.model_path(id)
		assert_true(ResourceLoader.exists(path), "%s model exists (%s)" % [id, path])
		var mdl: Node3D = Palette.model(path, 1.0)
		var ap := mdl.find_child("AnimationPlayer", true, false) as AnimationPlayer
		assert_true(ap != null, "%s model is animated" % id)
		if ap:
			assert_true(CreatureView.IDLE_ANIMS.any(func(n: StringName) -> bool: return ap.has_animation(n)), "%s has an idle CreatureView plays (%s)" % [id, ap.get_animation_list()])
		mdl.free()
	return true


func test_cute_models_textured_and_named() -> bool:
	for f: String in DirAccess.get_files_at("res://assets/monsters/cute"):
		if f.get_extension() != "fbx":
			continue
		var mdl: Node3D = Palette.model("res://assets/monsters/cute/" + f, 1.0)
		var meshes: Array[Node] = mdl.find_children("*", "MeshInstance3D", true, false)
		assert_true(not meshes.is_empty(), "%s has meshes" % f)
		for n: Node in meshes:
			var mi := n as MeshInstance3D
			for s: int in mi.mesh.get_surface_count():
				var m := mi.get_active_material(s) as BaseMaterial3D
				assert_true(m != null and m.albedo_texture != null, "%s surface %d has its painted texture" % [f, s])
		var ap := mdl.find_child("AnimationPlayer", true, false) as AnimationPlayer
		for a: String in ap.get_animation_list():
			assert_true(not "|" in a, "%s animation %s has a plain name" % [f, a])
		if f.get_basename() in FULL_CUTE:
			for want: StringName in [&"Idle", &"Walk", &"Bite_Front", &"HitRecieve", &"Death"]:
				assert_true(ap.has_animation(want), "%s plays %s" % [f, want])
		mdl.free()
	return true


func test_creature_view_walks_cute_model() -> bool:
	# A full cute model walks with its own animation instead of hopping.
	var cv: CreatureView = CreatureView.create(CardDB.card(&"snow_pup"))
	assert_true(not cv._hops, "Snow Pup walks with its own animation")
	cv.free()
	# A cute flyer without Idle/Walk flaps its Flying loop for both.
	cv = CreatureView.create(CardDB.card(&"lollibat"))
	assert_eq(cv._idle, &"Flying", "Lollibat idles by flapping")
	assert_true(not cv._hops, "Lollibat flies instead of hopping")
	cv.free()
	return true


func test_skinned_models_measured_as_drawn() -> bool:
	# The cute Mushroom's skeleton binding shrinks its mesh to ~58% when drawn: sizing must measure the drawn shape
	# (2.07 tall), not the unbound mesh (3.56), or Pain Shroom stands at about half height.
	var inst := (load("res://assets/monsters/cute/Mushroom.fbx") as PackedScene).instantiate() as Node3D
	var h: float = Palette.bounds(inst).size.y
	assert_true(absf(h - 2.07) < 0.15, "Mushroom measured as drawn (%.2f)" % h)
	inst.free()
	# A rig whose binding matches its skeleton measures the same as before (Yeti cub, 1.67 tall).
	inst = (load("res://assets/monsters/cute/Yeti.fbx") as PackedScene).instantiate() as Node3D
	h = Palette.bounds(inst).size.y
	assert_true(absf(h - 1.67) < 0.05, "Yeti unchanged (%.2f)" % h)
	inst.free()
	return true
