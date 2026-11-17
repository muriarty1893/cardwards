extends TestCase
## Settings autoload: defaults, clamping, persistence and recovery from a bad file.


func _make(p: String, wipe: bool) -> GameSettings:
	var s := GameSettings.new()
	s.path = p
	if wipe:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	return s


func test_defaults() -> bool:
	var s: GameSettings = _make("user://t_settings_a.cfg", true)
	s.load_settings()
	assert_eq(s.music_volume, 0.8, "music default")
	assert_eq(s.sfx_volume, 0.9, "sfx default")
	assert_eq(s.quality, GameSettings.default_quality(), "quality default")
	s.free()
	return true


func test_round_trip_and_clamp() -> bool:
	var s: GameSettings = _make("user://t_settings_b.cfg", true)
	s.set_value(&"music_volume", 1.4)
	s.set_value(&"sfx_volume", -1.0)
	s.set_value(&"quality", GameSettings.Quality.LOW)
	var t: GameSettings = _make("user://t_settings_b.cfg", false)
	t.load_settings()
	assert_eq(t.music_volume, 1.0, "clamped high")
	assert_eq(t.sfx_volume, 0.0, "clamped low")
	assert_eq(t.quality, GameSettings.Quality.LOW, "LOW kept")
	s.free()
	t.free()
	return true


func test_corrupt_file_gives_defaults() -> bool:
	var s: GameSettings = _make("user://t_settings_c.cfg", true)
	var f := FileAccess.open("user://t_settings_c.cfg", FileAccess.WRITE)
	f.store_string("garbage[[[ = \nquality=7\n")
	f.close()
	s.load_settings()
	assert_eq(s.music_volume, 0.8, "music default after corrupt file")
	assert_eq(s.quality, GameSettings.default_quality(), "default after unreadable file")
	s.free()
	return true


func test_camera_settings_defaults() -> bool:
	var s: GameSettings = _make("user://t_settings_cam_a.cfg", true)
	s.load_settings()
	assert_eq(s.battle_closeups, true, "close-ups on by default")
	assert_eq(s.zoom_speed, 1.0, "zoom speed default")
	s.free()
	return true


func test_camera_settings_roundtrip() -> bool:
	var s: GameSettings = _make("user://t_settings_cam_b.cfg", true)
	s.set_battle_closeups(false)
	s.set_zoom_speed(1.7)
	var t: GameSettings = _make("user://t_settings_cam_b.cfg", false)
	t.load_settings()
	assert_eq(t.battle_closeups, false, "close-ups saved")
	assert_true(absf(t.zoom_speed - 1.7) < 0.0001, "zoom speed saved")
	s.free()
	t.free()
	return true


func test_zoom_speed_clamped() -> bool:
	var s: GameSettings = _make("user://t_settings_cam_c.cfg", true)
	s.set_zoom_speed(9.0)
	assert_eq(s.zoom_speed, 2.0, "clamped high")
	s.set_zoom_speed(0.0)
	assert_eq(s.zoom_speed, 0.25, "clamped low")
	s.free()
	return true
