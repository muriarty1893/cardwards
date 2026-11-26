extends Node3D
## Dev: grids of monster models in the cartoon style.
##   --cards            the 24 creatures as VisualDB maps them, one land per row, sized by level
##   --group=<dir>      every model under res://assets/monsters/<dir> (for picking alternates)
##   --ids=a,b,c        just these cards, in a row, closer up (for checking new models)
##   godot --path . res://tools/contact_sheet.tscn -- --cards --shot=/tmp/sheet.png

## Standing height by level (spec 5.2).
const SIZES: Array[float] = [1.0, 1.0, 1.3, 1.7]


func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#8fd3ff")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.45
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 0.9
	add_child(sun)
	sun.look_at_from_position(Vector3(3, 8, 6), Vector3.ZERO)
	var cam := Camera3D.new()
	add_child(cam)
	var ids: PackedStringArray = []
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--ids="):
			ids = a.substr(6).split(",")
	if not ids.is_empty():
		_ids(ids)
		cam.fov = 32
		var far: float = 3.0 + 1.55 * ids.size()
		cam.look_at_from_position(Vector3(0, far * 0.56, far), Vector3(0, 0.55, 0))
	elif "--cards" in OS.get_cmdline_user_args():
		_cards()
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = 13.5
		cam.look_at_from_position(Vector3(0, 9.0, 13.0), Vector3(0, 0.4, 0.2))
	else:
		_group()
		cam.fov = 40
		cam.look_at_from_position(Vector3(0, 13, 17), Vector3(0, 0.5, 0))
	cam.make_current()
	Outline.attach(cam)


func _cards() -> void:
	var rows: Array[Array] = [[], [], [], []]
	for c: CardData in CardDB.all_cards():
		if c.is_creature() and c.land < rows.size():
			rows[c.land].append(c)
	for r: int in 4:
		var cards: Array = rows[r]
		for i: int in cards.size():
			var c: CardData = cards[i]
			var pos := Vector3((i - 2.5) * 2.75, 0, (r - 1.5) * 3.4)
			var mdl: Node3D = Palette.model(VisualDB.model_path(c.id), SIZES[c.level])
			Toon.apply(mdl, VisualDB.tint(c.id))
			mdl.position = pos
			add_child(mdl)
			_idle(mdl)
			_label("%s L%d" % [c.display_name, c.level], pos + Vector3(0, -0.1, 1.2))


func _ids(ids: PackedStringArray) -> void:
	for i: int in ids.size():
		var c: CardData = CardDB.card(StringName(ids[i]))
		var pos := Vector3((i - (ids.size() - 1) / 2.0) * 2.2, 0, 0)
		var mdl: Node3D = Palette.model(VisualDB.model_path(c.id), 1.6)
		Toon.apply(mdl, VisualDB.tint(c.id))
		mdl.position = pos
		add_child(mdl)
		_idle(mdl)
		_label(c.display_name, pos + Vector3(0, -0.1, 1.0))


func _group() -> void:
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
		var mdl: Node3D = Palette.model("res://assets/monsters/%s/%s" % [group, names[i]], 1.3)
		Toon.apply(mdl)
		var pos := Vector3((i % cols - (cols - 1) / 2.0) * 2.6, 0, (i / cols) * 3.0 - 3.0)
		mdl.position = pos
		add_child(mdl)
		_idle(mdl)
		_label(names[i].get_basename(), pos + Vector3(0, -0.15, 0.95))


func _idle(mdl: Node3D) -> void:
	var ap := mdl.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap:
		for n: String in ["Idle", "Flying_Idle"]:
			if ap.has_animation(n):
				ap.play(n)
				return


func _label(text: String, pos: Vector3) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 30
	l.pixel_size = 0.008
	l.outline_size = 12
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = pos
	add_child(l)
