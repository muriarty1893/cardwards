extends TestCase
## Sound sets all resolve to files; unknown sounds are ignored; volumes drive the buses.


func test_every_set_has_sounds() -> bool:
	var sets: Dictionary = GameAudio.SETS
	assert_eq(sets.size(), 24, "24 sets")
	for k: StringName in sets:
		assert_true((sets[k] as Array).size() >= 1, "%s has a file" % k)
		for p: String in sets[k]:
			assert_true(load(p) is AudioStream, "%s loads" % p)
	return true

func test_unknown_sound_is_safe() -> bool:
	var audio: Node = (Engine.get_main_loop() as SceneTree).root.get_node("Audio")
	audio.set("log_enabled", true)
	audio.call("sfx", &"nope")
	assert_true(not (&"nope" in (audio.get("played") as Array)), "not played")
	audio.set("log_enabled", false)
	return true

func test_volume_to_bus() -> bool:
	var settings: Node = (Engine.get_main_loop() as SceneTree).root.get_node("Settings")
	var old: float = settings.get("music_volume")
	settings.call("set_value", &"music_volume", 0.0)
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")), "0 mutes")
	settings.call("set_value", &"music_volume", 0.5)
	assert_true(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")) - linear_to_db(0.5)) < 0.01, "0.5 maps")
	settings.call("set_value", &"music_volume", old)
	return true
