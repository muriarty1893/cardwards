extends Node
## Dev helper (autoload). --fps-log=<seconds> prints frame rate and quits. With user arg --shot=<path>, moves the running scene into a fixed
## 1280x720 offscreen SubViewport (so the window manager's window size does not matter),
## saves it after --shot-frames=<n> frames (default 60) and quits. Does nothing otherwise.

const SIZE := Vector2i(1280, 720)

var _path: String = ""
## --fps-log=<seconds>: after a 2 s warm-up, sample frame times, print a summary and quit.
var _fps_secs: float = 0.0
var _fps_t: float = 0.0
var _fps_frames: int = 0
var _fps_worst: float = 0.0
var _cpu_proc: float = 0.0
var _rcpu: float = 0.0
var _rgpu: float = 0.0
var _frames: int = 60
var _vp: SubViewport


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_path = arg.substr(7)
		elif arg.begins_with("--shot-frames="):
			_frames = int(arg.substr(14))
		elif arg.begins_with("--fps-log="):
			_fps_secs = float(arg.substr(10))
	set_process(_path != "" or _fps_secs > 0.0)


func _process(delta: float) -> void:
	if _fps_secs > 0.0 and _vp != null:
		_log_fps(delta)
		return
	if _vp == null:
		var scene: Node = get_tree().current_scene
		if scene == null:
			return
		_vp = SubViewport.new()
		_vp.size = SIZE
		_vp.msaa_3d = Viewport.MSAA_DISABLED if Settings.quality == GameSettings.Quality.LOW else Viewport.MSAA_2X
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


func _log_fps(delta: float) -> void:
	_fps_t += delta
	if _fps_t < 2.0:
		return
	_fps_frames += 1
	_fps_worst = maxf(_fps_worst, delta)
	RenderingServer.viewport_set_measure_render_time(_vp.get_viewport_rid(), true)
	_cpu_proc += Performance.get_monitor(Performance.TIME_PROCESS)
	_rcpu += RenderingServer.viewport_get_measured_render_time_cpu(_vp.get_viewport_rid()) + RenderingServer.get_frame_setup_time_cpu()
	_rgpu += RenderingServer.viewport_get_measured_render_time_gpu(_vp.get_viewport_rid())
	if _fps_t >= 2.0 + _fps_secs:
		print("FPS avg %.1f, worst frame %.1f ms (%s, %s) | process %.1f ms, render cpu %.1f ms, render gpu %.1f ms, draw calls %d, prims %d" % [_fps_frames / (_fps_t - 2.0), _fps_worst * 1000.0, RenderingServer.get_video_adapter_name(), _vp.size, _cpu_proc / _fps_frames * 1000.0, _rcpu / _fps_frames, _rgpu / _fps_frames, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
		get_tree().quit()
