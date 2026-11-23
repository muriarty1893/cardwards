extends TestCase
## Every card has a visual entry, and every model file it names exists.


func test_entries_cover_all_cards() -> bool:
	assert_eq(VisualDB.ids().size(), CardDB.all_cards().size(), "one entry per card")
	for c: CardData in CardDB.all_cards():
		assert_true(VisualDB.ENTRIES.has(c.id), "entry for %s" % c.id)
		if c.kind != CardData.Kind.SPELL:
			assert_true(ResourceLoader.exists(VisualDB.model_path(c.id)), "model exists for %s" % c.id)
		assert_true(VisualDB.TINTS.has(VisualDB.ENTRIES[c.id].get("tint", &"none")), "tint name ok for %s" % c.id)
	return true


func test_buildings_have_badge_icons() -> bool:
	for c: CardData in CardDB.all_cards():
		if c.kind == CardData.Kind.BUILDING:
			assert_true(ResourceLoader.exists(VisualDB.badge_icon(c.id)), "badge icon for %s" % c.id)
	return true


func test_keyword_icons_exist_and_credited() -> bool:
	var credits: String = FileAccess.get_file_as_string("res://assets/CREDITS.md")
	for kw: StringName in Keywords.ORDER + [&"spell_power"]:
		assert_true(VisualDB.KEYWORD_ICONS.has(kw), "%s has an icon" % kw)
		assert_true(VisualDB.keyword_icon(kw) != null, "%s icon loads" % kw)
		assert_true(VisualDB.KEYWORD_COLORS.has(kw), "%s has a colour" % kw)
		var file: String = String(VisualDB.KEYWORD_ICONS[kw]).get_file().get_basename()
		assert_true(file in credits, "%s credited" % file)
	for path: String in [VisualDB.ICON_HEART, VisualDB.ICON_SWORDS, VisualDB.ICON_SPARKLE]:
		assert_true(load(path) is Texture2D, "%s loads" % path)
	return true


## The web build has no font with these symbols (they draw as boxes): code must use the icons instead.
func test_no_symbol_glyphs_in_ui_code() -> bool:
	var bad: Array = []
	for dir: String in ["res://view", "res://view/ui", "res://view/fx", "res://view/pieces", "res://view/board", "res://view/rivals", "res://menus"]:
		for f: String in DirAccess.get_files_at(dir):
			if not f.ends_with(".gd"):
				continue
			for line: String in FileAccess.get_file_as_string(dir + "/" + f).split("\n"):
				var code: String = line.split("#")[0]
				for g: String in ["♥", "⚔", "✦"]:
					if g in code:
						bad.append("%s/%s uses %s" % [dir, f, g])
	assert_eq(bad, [], "no symbol glyphs")
	return true
