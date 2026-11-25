@tool
extends EditorScenePostImport
## Import step for the extra free creature models (Quaternius, CC0: Easy Enemies, Animals, Farm Animals,
## Monsters, Dinosaurs, Platformer). Animations arrive as "Armature|Idle", "AnimalArmature|Idle" or with other
## names for standing still; this strips the prefix and names the idle clip "Idle" (and a walk "Walk"), so
## CreatureView finds them like on the other monster models.

const IDLE_NAMES: Array[String] = ["Idle", "Idle_2", "Idle_Normal", "Flying_Idle", "Fly", "Flying", "Swim", "Idle_Eating", "Eating"]
## Clip names that come with the model's name in front ("Rat_Walk").
const PREFIXED: Array[String] = ["Idle", "Attack", "Attack2", "Death", "Jump", "Run", "Running", "Walk", "Hit", "Flying", "Spawn"]
const WALK_NAMES: Array[String] = ["Walk", "Walking", "Run", "Gallop", "Jump", "Fast_Flying", "Swim_Fast", "Slither"]


## Old FBX files whose material colours don't come through: their surface colours, in surface order.
const SURFACE_COLORS: Dictionary = {
	"Fox": ["#e8803a", "#fff2e0"],
	"Bird": ["#f4f4f4", "#ffb03a"],
	"Fish": ["#ff8a5a"],
}


func _post_import(scene: Node) -> Object:
	var base: String = get_source_file().get_file().get_basename()
	# Old FBX files (Fox, Bird, Fish) keep the scene they were made in: sun lights, a lamp and a camera.
	# Left in, they light up the whole board while the creature is out.
	for n: Node in scene.find_children("*", "", true, false):
		if n is Light3D or n is Camera3D:
			n.get_parent().remove_child(n)
			n.free()
	if SURFACE_COLORS.has(base):
		var cols: Array = SURFACE_COLORS[base]
		for n: Node in scene.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			for s: int in mi.mesh.get_surface_count():
				var m := StandardMaterial3D.new()
				m.resource_name = "Painted"
				m.albedo_color = Color(cols[mini(s, cols.size() - 1)])
				mi.set_surface_override_material(s, m)
	for n: Node in scene.find_children("*", "AnimationPlayer", true, false):
		var ap := n as AnimationPlayer
		for lib_name: StringName in ap.get_animation_library_list():
			var lib: AnimationLibrary = ap.get_animation_library(lib_name)
			for a: StringName in lib.get_animation_list():
				var plain: String = String(a).get_slice("|", String(a).get_slice_count("|") - 1)
				# "Frog_Idle" → "Idle" (the model's name as a prefix).
				var parts: PackedStringArray = plain.split("_", true, 1)
				if parts.size() == 2 and parts[1] in PREFIXED:
					plain = parts[1]
				if plain != String(a) and not lib.has_animation(plain):
					lib.rename_animation(a, plain)
			_alias(lib, "Idle", IDLE_NAMES)
			_alias(lib, "Walk", WALK_NAMES)
			_alias(lib, "Bite_Front", ["Attack", "Attack2", "Attack_Headbutt", "Attack_Kick"])
			_alias(lib, "HitReact", ["Hit", "Idle_HitReact1"])
			# Models with a single clip (a loop): use it for standing too.
			var all: PackedStringArray = lib.get_animation_list()
			if not lib.has_animation("Idle") and all.size() > 0:
				lib.add_animation("Idle", lib.get_animation(all[0]).duplicate())
			for a: StringName in lib.get_animation_list():
				if String(a) in ["Idle", "Walk", "Flying", "Flying_Idle", "Swim"]:
					lib.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	return scene


## Gives `lib` a clip called `want` from the first of `names` it has (case-insensitive).
static func _alias(lib: AnimationLibrary, want: String, names: Array[String]) -> void:
	if lib.has_animation(want):
		return
	for cand: String in names:
		for a: StringName in lib.get_animation_list():
			if String(a).to_lower() == cand.to_lower():
				lib.add_animation(want, lib.get_animation(a).duplicate())
				return
