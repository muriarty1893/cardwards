extends Node
## Dev tool: renders every card's picture (and the two hero portraits) in the cartoon style
## and saves PNGs into res://assets/card_art/. Run windowed (it needs the GPU):
##   godot --path . res://tools/bake_card_art.tscn [-- --only=<id>]
## Creatures and buildings: their own model standing on a strip of their land.
## Spells: their icon over a glow in the land's colour. Heroes: KayKit Mage / Barbarian.

const OUT := "res://assets/card_art/%s.png"
const CARD := Vector2i(320, 240)
const HERO := Vector2i(256, 256)
const SUPERSAMPLE := 2
const FOV := 30.0
## Camera comes from the front-right and a little above.
const VIEW_DIR := Vector3(0.42, 0.36, 1.0)

var _vp: SubViewport
var _env: Environment
var _cam: Camera3D
var _stage: Node3D


func _ready() -> void:
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.msaa_3d = Viewport.MSAA_4X
	add_child(_vp)
	var root := Node3D.new()
	_vp.add_child(root)
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color.WHITE
	_env.ambient_light_energy = 0.45
	_env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = _env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#fff4e0")
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	root.add_child(sun)
	sun.look_at_from_position(Vector3(4, 9, 6), Vector3.ZERO)
	_cam = Camera3D.new()
	_cam.fov = FOV
	root.add_child(_cam)
	_cam.make_current()
	Outline.attach(_cam)
	_stage = Node3D.new()
	root.add_child(_stage)
	_bake_all.call_deferred()


func _bake_all() -> void:
	var only: String = ""
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/card_art"))
	var n: int = 0
	for c: CardData in CardDB.all_cards():
		if only != "" and only != String(c.id):
			continue
		await _bake_card(c)
		n += 1
	for h: Array in [["hero_you", "res://assets/heroes/Mage.glb", Color("#8fd3ff")], ["hero_rival", "res://assets/heroes/Barbarian.glb", Color("#ffb3dd")]]:
		if only != "" and only != h[0]:
			continue
		await _bake_hero(h[0], h[1], h[2])
		n += 1
	print("baked %d images" % n)
	get_tree().quit()


func _clear() -> void:
	for ch: Node in _stage.get_children():
		ch.free()


func _bake_card(c: CardData) -> void:
	_clear()
	_env.background_color = VisualDB.ART_SKY[c.land]
	_vp.size = CARD * SUPERSAMPLE
	_stage.add_child(_land_strip(c.land))
	var subject: Node3D
	if c.kind == CardData.Kind.CREATURE:
		var v := CreatureView.create(c)
		v.set_process(false)
		v.position.y = CreatureView.BASE_Y - Island.TOP_Y
		v.rotation.y = 0.35
		subject = v
	elif c.kind == CardData.Kind.BUILDING:
		var b := BuildingView.create(c)
		b.position.y = -Island.TOP_Y
		b.rotation.y = 0.5
		b.scale = Vector3.ONE * 1.4
		subject = b
	else:
		subject = _spell_subject(c)
	_stage.add_child(subject)
	_pose(subject)
	var box: AABB = _world_bounds(subject)
	if box.size == Vector3.ZERO:
		# Sprites have no mesh bounds: frame the icon's fixed spot.
		box = AABB(Vector3(-0.8, 0.25, -0.3), Vector3(1.6, 1.4, 0.6))
	_frame(box, 1.08, 0.06)
	await _save(OUT % c.id, CARD)


## Icon card picture: the spell's icon standing up, a soft glow behind it.
func _spell_subject(c: CardData) -> Node3D:
	var holder := Node3D.new()
	var glow := Sprite3D.new()
	var g := GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1.0, 0.5)
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(VisualDB.SPELL_GLOW[c.land], 0.95), Color(VisualDB.SPELL_GLOW[c.land], 0.0)])
	g.gradient = grad
	g.width = 256
	g.height = 256
	glow.texture = g
	glow.pixel_size = 2.4 / 256.0
	glow.shaded = false
	glow.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glow.position = Vector3(0, 0.95, -0.25)
	holder.add_child(glow)
	var icon := Sprite3D.new()
	icon.texture = load(VisualDB.SPELL_ICONS[c.id]) as Texture2D
	icon.pixel_size = 1.35 / float(icon.texture.get_height())
	icon.shaded = false
	icon.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	icon.modulate = Color.WHITE
	icon.position = Vector3(0, 0.95, 0)
	holder.add_child(icon)
	return holder


func _land_strip(land: int) -> Node3D:
	var isl := Island.new()
	isl.setup(land, 0, 0)
	isl.position = Vector3(0, -Island.TOP_Y, -0.6)
	isl.scale = Vector3(1.6, 1.0, 1.0)
	# No props in the picture, just the painted ground.
	var props: Node = isl.find_child("Dressing", true, false)
	if props:
		props.free()
	return isl


func _bake_hero(id: String, path: String, bg: Color) -> void:
	_clear()
	_env.background_color = bg
	_vp.size = HERO * SUPERSAMPLE
	var mdl: Node3D = Palette.model(path, 2.0)
	Toon.apply(mdl)
	mdl.rotation.y = 0.3
	_stage.add_child(mdl)
	_pose(mdl)
	# Head and shoulders. Skinned-mesh bounds include held items, so frame by hand:
	# the model is 2.0 tall with its base at y = 0.
	var center := Vector3(0, 1.5, 0)
	_cam.look_at_from_position(center + Vector3(0.25, 0.12, 1.0).normalized() * 2.8, center)
	await _save(OUT % id, HERO)


## Seek idle a little way in so the pose isn't the bind pose.
func _pose(n: Node) -> void:
	var ap := n.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null:
		return
	for a: String in ["Idle", "Flying_Idle", "Idle_Neutral"]:
		if ap.has_animation(a):
			ap.play(a)
			ap.seek(0.3, true)
			ap.pause()
			return


func _world_bounds(n: Node3D) -> AABB:
	var local: AABB = Palette.bounds(n)
	return n.transform * local


## Points the camera at `box` from VIEW_DIR, far enough that it fills `fill` of the frame.
func _frame(box: AABB, margin: float, lift: float) -> void:
	var center: Vector3 = box.get_center() + Vector3(0, box.size.y * lift, 0)
	var aspect: float = float(_vp.size.x) / float(_vp.size.y)
	var half_v: float = deg_to_rad(FOV) / 2.0
	var need_v: float = box.size.y * 0.5 * margin
	var need_h: float = maxf(box.size.x, box.size.z) * 0.5 * margin / aspect
	var dist: float = maxf(need_v, need_h) / tan(half_v) + maxf(box.size.x, box.size.z) * 0.25
	_cam.look_at_from_position(center + VIEW_DIR.normalized() * dist, center)


func _save(path: String, out_size: Vector2i) -> void:
	for i: int in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img: Image = _vp.get_texture().get_image()
	img.resize(out_size.x, out_size.y, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(path))
	print("baked ", path)
