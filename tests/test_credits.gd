extends TestCase
## Credits cover every asset folder; the cartoon title font loads.


func test_credits_cover_every_asset_dir() -> bool:
	var text: String = FileAccess.get_file_as_string("res://assets/CREDITS.md")
	for d: String in DirAccess.get_directories_at("res://assets"):
		if d == "card_art":
			continue  # baked by us from credited models
		assert_true(("assets/%s" % d) in text or ("`%s/`" % d) in text, "CREDITS mentions %s" % d)
	for s: String in ["Quaternius", "Kenney", "game-icons.net", "CC BY 3.0", "Lilita One", "KayKit"]:
		assert_true(s in text, "credits mention %s" % s)
	return true

func test_title_font_loads() -> bool:
	var l: Label = UiStyle.title(Label.new())
	assert_true(l.get_theme_font("font") is FontFile, "Lilita One applied")
	l.free()
	return true


func test_export_presets_ship_credits() -> bool:
	# CREDITS.md and licence .txt files are not resources: exports drop them unless included.
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://export_presets.cfg"), OK, "export presets exist")
	var presets: int = 0
	for section: String in cfg.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options"):
			presets += 1
			var inc: String = cfg.get_value(section, "include_filter", "")
			for f: String in ["CREDITS.md", "OFL.txt", "LICENSE.txt"]:
				assert_true(f in inc, "%s includes %s" % [cfg.get_value(section, "name", section), f])
	assert_true(presets >= 2, "Linux and Windows presets")
	return true
