extends Node3D
## Dev: grid of every monster model in a group with its name, for picking card art.
##   godot --path . res://tools/contact_sheet.tscn -- --group=blob --shot=/tmp/sheet.png


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#8fd3ff")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.look_at_from_position(Vector3(3, 8, 6), Vector3.ZERO)
	var group: String = "blob"
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--group="):
			group = a.substr(8)
	var names: Array[String] = []
	for f: String in ResourceLoader.list_directory("res://assets/monsters/" + group):
		if f.ends_with(".gltf"):
			names.append(f)
	var cols: int = 6
	for i: int in names.size():
		var inst := (load("res://assets/monsters/%s/%s" % [group, names[i]]) as PackedScene).instantiate() as Node3D
		add_child(inst)
		var x: float = (i % cols - (cols - 1) / 2.0) * 3.2
		var z: float = (i / cols) * 4.0 - 4.0
		inst.position = Vector3(x, 0, z)
		var ap := inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
		if ap:
			for n: String in ["Idle", "Flying_Idle"]:
				if ap.has_animation(n):
					ap.play(n)
		var l := Label3D.new()
		l.text = names[i].get_basename()
		l.font_size = 64
		l.outline_size = 16
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.position = Vector3(x, -0.3, z + 1.2)
		add_child(l)
	var cam := Camera3D.new()
	add_child(cam)
	cam.fov = 40
	cam.look_at_from_position(Vector3(0, 13, 17), Vector3(0, 0.5, 0))
	cam.make_current()
