extends SceneTree
## Headless test runner.
##   godot --headless --path . --script res://tests/run_tests.gd [-- --only=<substring>]

var passed: int = 0
var failed: int = 0


func _initialize() -> void:
	var only: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.substr(7)
	var files: PackedStringArray = DirAccess.get_files_at("res://tests")
	files.sort()
	for file: String in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		var script: Script = load("res://tests/" + file)
		if script == null:
			failed += 1
			push_error("FAIL %s: did not load" % file)
			continue
		var suite: Object = script.new()
		for m: Dictionary in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			if only != "" and not (only in file or only in name):
				continue
			suite.set("current", file.get_basename() + "." + name)
			var result: Variant = await suite.call(name)
			if result != true:
				failed += 1
				push_error("FAIL %s.%s: did not finish (runtime error?)" % [file, name])
		passed += int(suite.get("passed"))
		failed += int(suite.get("failed"))
	print("Results: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
