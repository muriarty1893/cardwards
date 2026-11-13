extends Node
## Dev helper (autoload). With user arg --shot=<path>, moves the running scene into a fixed
## 1280x720 offscreen SubViewport (so the window manager's window size does not matter),
## saves it after --shot-frames=<n> frames (default 60) and quits. Does nothing otherwise.

const SIZE := Vector2i(1280, 720)

var _path: String = ""
var _frames: int = 60
var _vp: SubViewport


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_path = arg.substr(7)
		elif arg.begins_with("--shot-frames="):
			_frames = int(arg.substr(14))
	set_process(_path != "")


func _process(_delta: float) -> void:
	if _vp == null:
		var scene: Node = get_tree().current_scene
		if scene == null:
			return
		_vp = SubViewport.new()
		_vp.size = SIZE
		_vp.msaa_3d = Viewport.MSAA_2X
		_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		get_tree().root.add_child(_vp)
		scene.reparent(_vp, false)
		return
	_frames -= 1
	if _frames > 0:
		return
	_vp.get_texture().get_image().save_png(_path)
	print("screenshot saved: ", _path)
	get_tree().quit()
