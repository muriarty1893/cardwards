class_name RivalSeat
extends Node3D
## The rival hero sitting in a chair across the table, holding a fan of cards. The legs stay in
## the seated pose; the upper body holds the cards and plays reactions (lean in to play a card,
## cheer, flinch) blended over it. Thinking turns the head; losing slumps the back and head.

const SIT := &"Sit_Chair_Idle"
## Upper-body pose that holds the card fan up beside the face (chosen by screenshot); the head
## keeps the seated pose so the rival looks at the board.
const HOLD := &"1H_Ranged_Aiming"
## The aiming clip starts with the arm down and raises it; only this raised stretch (clip seconds)
## is played, back and forth, so the fan never drops to the table and swings back up. Both ends
## sit at the top of the arm's small breathing sway, so the turnarounds are smooth.
const HOLD_FROM := 0.55
const HOLD_TO := 1.0667
const PLAY := &"Interact"
const CHEER := &"Cheer"
const FLINCH := &"Hit_A"
## Held weapons and props in the KayKit model that a card player has put away.
const HIDE: Array[String] = ["1H_Axe_Offhand", "Barbarian_Round_Shield", "1H_Axe", "2H_Axe", "Mug", "Barbarian_Cape"]
## KayKit units → board units for the seated model: a little under furniture scale, so from the
## player's seat the rival reads as across the table without crowding the board.
const MODEL_SCALE := Room.SCALE * 0.86
## The model sits this much higher than a plain chair would put it, so its chest and the card
## fan clear the tabletop; the chair is stretched taller to match (seat at ~0.55 KayKit units).
const LIFT := 2.4
## The seated pose puts the hips behind the model's root; this moves them onto the seat.
const FORWARD := 2.6
const CHAIR_K := Vector3(Room.SCALE, Room.SCALE + LIFT / 0.55, Room.SCALE)
const CARD_BACK := Color("#6a46c8")
const CARD_RIM := Color("#ffcf3a")

var model: Node3D
var skeleton: Skeleton3D
var _anim: AnimationPlayer
var _tree: AnimationTree
var _react_node: AnimationNodeAnimation
var _pose: Pose
var _fan: Node3D
var _cards: Array[Node3D] = []
var _react: StringName = &""
var _react_left: float = 0.0
var _winning: bool = false


## Bends bones after the animation: a slow head turn while thinking, a slump when losing.
class Pose extends SkeletonModifier3D:
	var think: float = 0.0
	var slump: float = 0.0
	var _t: float = 0.0

	func _process_modification_with_delta(delta: float) -> void:
		_t += delta
		var sk: Skeleton3D = get_skeleton()
		if sk == null or (think <= 0.0 and slump <= 0.0):
			return
		var head: int = sk.find_bone("head")
		var spine: int = sk.find_bone("spine")
		if head >= 0:
			var yaw: float = sin(_t * 0.9) * 0.4 * think
			var pitch: float = 0.55 * slump + 0.12 * think
			sk.set_bone_pose_rotation(head, sk.get_bone_pose_rotation(head) * Quaternion(Vector3.UP, yaw) * Quaternion(Vector3.RIGHT, pitch))
		if spine >= 0 and slump > 0.0:
			sk.set_bone_pose_rotation(spine, sk.get_bone_pose_rotation(spine) * Quaternion(Vector3.RIGHT, 0.35 * slump))


func setup(model_path: String) -> void:
	position = Vector3(0, Room.FLOOR_Y, Room.SEAT_Z)
	add_child(Room.model("chair_A_wood", CHAIR_K))
	model = (load(model_path) as PackedScene).instantiate() as Node3D
	model.scale = Vector3.ONE * MODEL_SCALE
	model.position = Vector3(0, LIFT, FORWARD)
	add_child(model)
	for n: String in HIDE:
		var node: Node = model.find_child(n, true, false)
		if node is Node3D:
			(node as Node3D).visible = false
	Toon.apply(model)
	skeleton = model.find_child("Skeleton3D", true, false) as Skeleton3D
	_anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_anim.stop()
	_build_tree()
	_pose = Pose.new()
	skeleton.add_child(_pose)
	_build_fan()


func _upper_paths(include_head: bool = true) -> Array[NodePath]:
	var upper: Dictionary = {}
	var spine: int = skeleton.find_bone("spine")
	for b: int in skeleton.get_bone_count():
		var p: int = b
		while p >= 0:
			if p == spine:
				upper[skeleton.get_bone_name(b)] = true
				break
			p = skeleton.get_bone_parent(p)
	var out: Array[NodePath] = []
	var a: Animation = _anim.get_animation(SIT)
	for t: int in a.get_track_count():
		var path: NodePath = a.track_get_path(t)
		var bone: String = path.get_concatenated_subnames()
		if upper.has(bone) and (include_head or bone != "head"):
			out.append(path)
	return out


func _looping(anim: StringName) -> AnimationNodeAnimation:
	var n := AnimationNodeAnimation.new()
	n.animation = anim
	n.use_custom_timeline = true
	n.timeline_length = _anim.get_animation(anim).length
	n.stretch_time_scale = false
	n.loop_mode = Animation.LOOP_LINEAR
	return n


## Plays clip seconds [from, to] back and forth forever.
func _held(anim: StringName, from: float, to: float) -> AnimationNodeAnimation:
	var n := AnimationNodeAnimation.new()
	n.animation = anim
	n.use_custom_timeline = true
	n.start_offset = from
	n.timeline_length = minf(to, _anim.get_animation(anim).length) - from
	n.stretch_time_scale = false
	n.loop_mode = Animation.LOOP_PINGPONG
	return n


func _build_tree() -> void:
	var bt := AnimationNodeBlendTree.new()
	var paths: Array[NodePath] = _upper_paths()
	var hold := AnimationNodeBlend2.new()
	var win := AnimationNodeBlend2.new()
	var shot := AnimationNodeOneShot.new()
	shot.fadein_time = 0.15
	shot.fadeout_time = 0.3
	for f: AnimationNode in [win, shot]:
		f.filter_enabled = true
		for p: NodePath in paths:
			f.set_filter_path(p, true)
	hold.filter_enabled = true
	for p: NodePath in _upper_paths(false):
		hold.set_filter_path(p, true)
	_react_node = AnimationNodeAnimation.new()
	_react_node.animation = PLAY
	bt.add_node(&"sit", _looping(SIT))
	bt.add_node(&"hold_pose", _held(HOLD, HOLD_FROM, HOLD_TO))
	bt.add_node(&"hold", hold)
	bt.add_node(&"react", _react_node)
	bt.add_node(&"shot", shot)
	bt.add_node(&"cheer", _looping(CHEER))
	bt.add_node(&"win", win)
	bt.connect_node(&"hold", 0, &"sit")
	bt.connect_node(&"hold", 1, &"hold_pose")
	bt.connect_node(&"shot", 0, &"hold")
	bt.connect_node(&"shot", 1, &"react")
	bt.connect_node(&"win", 0, &"shot")
	bt.connect_node(&"win", 1, &"cheer")
	bt.connect_node(&"output", 0, &"win")
	_tree = AnimationTree.new()
	_tree.name = "Upper"
	_anim.get_parent().add_child(_tree)
	_tree.tree_root = bt
	_tree.anim_player = _tree.get_path_to(_anim)
	_tree.active = true
	_tree.set(&"parameters/hold/blend_amount", 1.0)
	_tree.set(&"parameters/win/blend_amount", 0.0)


## The fan of card backs in the right hand; set_hand_count keeps it matching the rival's hand.
func _build_fan() -> void:
	var attach := BoneAttachment3D.new()
	attach.bone_name = "handslot.r"
	skeleton.add_child(attach)
	_fan = Node3D.new()
	_fan.name = "CardFan"
	attach.add_child(_fan)
	set_hand_count(5, false)


func _make_card() -> Node3D:
	var back := BoxMesh.new()
	back.size = Vector3(0.27, 0.39, 0.004)
	var rim := BoxMesh.new()
	rim.size = Vector3(0.31, 0.43, 0.006)
	var card := Node3D.new()
	card.add_child(Palette.mesh(rim, Toon.plain(CARD_RIM), Vector3(0, 0.2, 0)))
	for side: float in [-1.0, 1.0]:
		card.add_child(Palette.mesh(back, Toon.plain(CARD_BACK), Vector3(0, 0.2, side * 0.004)))
	return card


## Cards held in the fan now.
func hand_count() -> int:
	return _cards.size()


## Shows n card backs (0..hand limit). New cards slide up into the fan, played ones drop out,
## and the fan re-spreads: 16° apart, closer together when the hand is big.
func set_hand_count(n: int, animate: bool = true) -> void:
	n = clampi(n, 0, GameState.HAND_LIMIT + 1)
	while _cards.size() < n:
		var card: Node3D = _make_card()
		_fan.add_child(card)
		_cards.append(card)
		if animate:
			card.position = Vector3(0, -0.35, 0.012 * (_cards.size() - 1))
			card.scale = Vector3.ONE * 0.4
	while _cards.size() > n:
		var gone: Node3D = _cards.pop_back()
		if animate and gone.is_inside_tree():
			var tw := gone.create_tween().set_parallel()
			tw.tween_property(gone, "position", gone.position + Vector3(0, 0.45, 0.05), 0.25)
			tw.tween_property(gone, "scale", Vector3.ONE * 0.2, 0.25)
			tw.chain().tween_callback(gone.queue_free)
		else:
			gone.free()
	var step: float = 16.0 if _cards.size() <= 5 else 64.0 / (_cards.size() - 1)
	for i: int in _cards.size():
		var card: Node3D = _cards[i]
		var rot: float = deg_to_rad(step * (_cards.size() - 1) * 0.5 - step * i)
		var pos := Vector3(0, 0, 0.012 * i)
		if animate and card.is_inside_tree():
			var tw := card.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(card, "rotation:z", rot, 0.3)
			tw.tween_property(card, "position", pos, 0.3)
			tw.tween_property(card, "scale", Vector3.ONE, 0.3)
		else:
			card.rotation.z = rot
			card.position = pos
			card.scale = Vector3.ONE


func _process(delta: float) -> void:
	if _react_left > 0.0:
		_react_left -= delta
	# Whatever the hand bone does, the fan shows its backs to the player, tipped back a little.
	if _fan:
		_fan.global_basis = Basis(Vector3.RIGHT, -0.3).scaled(Vector3.ONE * MODEL_SCALE)


## The upper-body clip the rival is showing now (SIT when it is just holding its cards).
func upper_anim() -> StringName:
	if _winning:
		return CHEER
	if _react_left > 0.0:
		return _react
	return SIT


func clip_length(anim: StringName) -> float:
	return _anim.get_animation(anim).length


func bone_position(bone: StringName) -> Vector3:
	var i: int = skeleton.find_bone(bone)
	return skeleton.global_transform * skeleton.get_bone_global_pose(i).origin


func play_card() -> void:
	_fire(PLAY)


func cheer() -> void:
	_fire(CHEER)


func flinch() -> void:
	_fire(FLINCH)


func think(on: bool) -> void:
	create_tween().tween_property(_pose, "think", 1.0 if on else 0.0, 0.5)


func lose() -> void:
	_winning = false
	create_tween().tween_property(_pose, "slump", 1.0, 0.8).set_trans(Tween.TRANS_SINE)


func win() -> void:
	_winning = true
	create_tween().tween_property(_tree, "parameters/win/blend_amount", 1.0, 0.3)


func _fire(anim: StringName) -> void:
	_react = anim
	_react_left = clip_length(anim)
	_react_node.animation = anim
	_tree.set(&"parameters/shot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


## Screen rect of the seated rival from the tabletop up to the top of the head, shoulder wide.
func hero_rect(cam: Camera3D) -> Rect2:
	var head: Vector3 = bone_position(&"head")
	var chest: Vector3 = bone_position(&"chest")
	var k: float = MODEL_SCALE
	var pts: Array[Vector3] = [
		head + Vector3(0, 0.9 * k, 0),
		chest + Vector3(-0.75 * k, 0, 0), chest + Vector3(0.75 * k, 0, 0),
		Vector3(chest.x - 0.75 * k, 0.0, Room.TABLE_RECT.position.y), Vector3(chest.x + 0.75 * k, 0.0, Room.TABLE_RECT.position.y),
	]
	var r := Rect2(cam.unproject_position(pts[0]), Vector2.ZERO)
	for p: Vector3 in pts:
		r = r.expand(cam.unproject_position(p))
	return r


func hand_point() -> Vector3:
	return _fan.global_position
