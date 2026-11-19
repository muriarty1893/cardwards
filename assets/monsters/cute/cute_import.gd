@tool
extends EditorScenePostImport
## Import step for the Cute Animated Monsters (Quaternius, CC0). The FBX files don't link their painted textures and
## name animations "MonsterArmature|Walk". This gives every surface its texture (textures/<Name>_Texture.png, already
## brightened x1.5 for the game's lighting) and strips the armature prefix, so CreatureView finds Idle, Walk,
## Bite_Front, HitRecieve, Death... like on the other monster models.


func _post_import(scene: Node) -> Object:
	var src: String = get_source_file()
	var tex := load(src.get_base_dir() + "/textures/%s_Texture.png" % src.get_file().get_basename()) as Texture2D
	for n: Node in scene.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for s: int in mi.mesh.get_surface_count():
			var m := StandardMaterial3D.new()
			m.resource_name = "Painted"
			m.albedo_texture = tex
			mi.set_surface_override_material(s, m)
	for n: Node in scene.find_children("*", "AnimationPlayer", true, false):
		var ap := n as AnimationPlayer
		for lib_name: StringName in ap.get_animation_library_list():
			var lib: AnimationLibrary = ap.get_animation_library(lib_name)
			for a: StringName in lib.get_animation_list():
				var plain: String = String(a).get_slice("|", String(a).get_slice_count("|") - 1)
				if plain != String(a) and not lib.has_animation(plain):
					lib.rename_animation(a, plain)
	return scene
