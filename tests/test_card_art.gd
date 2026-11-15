extends TestCase
## Every card has a baked 320x240 picture; both hero portraits exist at 256x256.


func _size(path: String) -> Vector2i:
	var tex := load(path) as Texture2D
	return Vector2i(tex.get_width(), tex.get_height()) if tex else Vector2i.ZERO


func test_all_card_art_present() -> bool:
	for c: CardData in CardDB.all_cards():
		var p: String = VisualDB.art_path(c.id)
		assert_true(ResourceLoader.exists(p), "art exists for %s" % c.id)
		if ResourceLoader.exists(p):
			assert_eq(_size(p), Vector2i(320, 240), "art size for %s" % c.id)
	for h: String in ["hero_you", "hero_rival"]:
		var p: String = "res://assets/card_art/%s.png" % h
		assert_true(ResourceLoader.exists(p), "%s exists" % h)
		if ResourceLoader.exists(p):
			assert_eq(_size(p), Vector2i(256, 256), "%s size" % h)
	return true


func test_spell_icons_known() -> bool:
	for c: CardData in CardDB.all_cards():
		if c.kind == CardData.Kind.SPELL:
			assert_true(VisualDB.SPELL_ICONS.has(c.id), "icon for %s" % c.id)
			assert_true(ResourceLoader.exists(VisualDB.SPELL_ICONS.get(c.id, "")), "icon file for %s" % c.id)
	return true
