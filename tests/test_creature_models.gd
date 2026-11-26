extends TestCase
## Creature models (made in Blender by art_src/forge): every creature has a model of its own, every model loads
## and plays each clip CreatureView asks for.

## The clips every model brings, plus one fidget from CreatureView.FIDGET_ANIMS (forged ones use Yes).
const CLIPS: Array[StringName] = [&"Idle", &"Walk", &"Punch", &"HitReact", &"Death"]


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


func test_models_play_every_clip() -> bool:
	for id: StringName in _creature_ids():
		var mdl: Node3D = Palette.model(VisualDB.model_path(id), 1.0)
		assert_true(not mdl.find_children("*", "MeshInstance3D", true, false).is_empty(), "%s has meshes" % id)
		var ap := mdl.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap:
			for want: StringName in CLIPS:
				assert_true(ap.has_animation(want), "%s plays %s" % [id, want])
			assert_true(CreatureView.FIDGET_ANIMS.any(func(n: StringName) -> bool: return ap.has_animation(n)),
					"%s has a fidget" % id)
		mdl.free()
	return true


func test_creature_view_walks_its_model() -> bool:
	# A walker walks with its own Walk clip instead of hopping.
	var cv: CreatureView = CreatureView.create(CardDB.card(&"snow_pup"))
	assert_true(not cv._hops, "Snow Pup walks with its own animation")
	cv.free()
	# A flyer idles and travels with its own clips too.
	cv = CreatureView.create(CardDB.card(&"lollibat"))
	assert_eq(cv._idle, &"Idle", "Lollibat idles with its Idle clip")
	assert_true(not cv._hops, "Lollibat flies instead of hopping")
	cv.free()
	return true


func test_skinned_models_measured_as_drawn() -> bool:
	# Sizing measures the drawn (skinned) shape: forged models come out as tall as they were built in Blender.
	for pair: Array in [[&"grave_toad", 1.16], [&"the_rot_king", 2.77]]:
		var inst := (load(VisualDB.model_path(pair[0])) as PackedScene).instantiate() as Node3D
		var h: float = Palette.bounds(inst).size.y
		assert_true(absf(h - float(pair[1])) < 0.1, "%s measured as drawn (%.2f)" % [pair[0], h])
		inst.free()
	return true


## Some old FBX files come with the scene they were made in: sun lights, a lamp and a camera. Those would
## light up the whole board while the creature is out (the Sand Fox did), so the import leaves them out.
func test_models_bring_no_lights_or_cameras() -> bool:
	for id: StringName in _creature_ids():
		var mdl: Node3D = Palette.model(VisualDB.model_path(id), 1.0)
		for n: Node in mdl.find_children("*", "", true, false):
			assert_true(not (n is Light3D or n is Camera3D), "%s model has no %s (%s)" % [id, n.get_class(), n.name])
		mdl.free()
	return true
