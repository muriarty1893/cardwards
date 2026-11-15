# Dev check: compile every .gdshader headless and print SHADER ERROR lines if any fail.
#   godot --headless --path . --script res://tools/compile_shaders.gd > shaders.log 2>&1
#   grep -nE "SHADER ERROR|Shader compilation failed" shaders.log   # no output = pass
extends SceneTree


func _initialize() -> void:
	var paths: PackedStringArray = _find("res://", "gdshader")
	var forward_plus: bool = RenderingServer.get_current_rendering_method() == "forward_plus"
	for path: String in paths:
		if path.ends_with("/outline.gdshader") and not forward_plus:
			print("skipping ", path, " (Forward+ only; Outline uses outline_depth.gdshader here)")
			continue
		print("compiling ", path)
		var shader := load(path) as Shader
		shader.get_shader_uniform_list()
	print("Compiled %d shaders" % paths.size())
	quit(0)


func _find(dir: String, ext: String) -> PackedStringArray:
	var found := PackedStringArray()
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() == ext:
			found.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		if not sub.begins_with("."):
			found.append_array(_find(dir.path_join(sub), ext))
	return found
