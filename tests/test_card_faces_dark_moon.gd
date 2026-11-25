extends TestCase
## Card faces for the Dark Moon expansion (spec 6): legendary crown, curse frame, changed numbers, gift marker.


func _w(c: CardData) -> CardWidget:
	var w := CardWidget.new()
	w.setup(c, 0)
	return w


func test_legendary_has_a_crown() -> bool:
	var w: CardWidget = _w(CardDB.card(&"dark_moon"))
	assert_true(w.find_child("Crown", true, false) != null, "crown on a legendary")
	w.free()
	var p: CardWidget = _w(CardDB.card(&"gumdrop"))
	assert_true(p.find_child("Crown", true, false) == null, "no crown otherwise")
	p.free()
	return true


func test_curse_frame() -> bool:
	var w: CardWidget = _w(CardDB.card(&"nightmare"))
	assert_eq(w.frame_color(), CardWidget.CURSE_FRAME, "curses get the purple-black frame")
	w.free()
	return true


func test_changed_numbers_are_coloured() -> bool:
	var up: CardWidget = _w(CardDB.variant(CardDB.card(&"gumdrop"), {"attack": 2, "health": -1}))
	assert_eq(up.attack_label().get_theme_color("font_color"), CardWidget.DISCOUNT, "higher attack in green")
	assert_eq(up.health_label().get_theme_color("font_color"), CardWidget.WORSE, "lower health in red")
	up.free()
	var cheap: CardWidget = _w(CardDB.variant(CardDB.card(&"gumdrop"), {"cost": -1}))
	assert_eq(cheap.cost_label().get_theme_color("font_color"), CardWidget.DISCOUNT, "cheaper cost in green")
	cheap.free()
	var gift: CardWidget = _w(CardDB.variant(CardDB.card(&"gumdrop"), Gifts.delta(&"guard")))
	assert_true(gift.find_child("GiftMark", true, false) != null, "Dark Gift marker")
	gift.free()
	return true
