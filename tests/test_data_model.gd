extends TestCase

func test_effect_data_defaults() -> bool:
	var e := EffectData.new()
	assert_eq(e.who, &"own_hero", "default who")
	assert_eq(e.filter_kind, -1, "no kind filter")
	assert_true(not e.combo, "not combo")
	return true

func test_card_effect_lookup() -> bool:
	var c: CardData = Fx.card(&"t", CardData.Kind.CREATURE, 2, 1, 2, [&"guard"], [
		Fx.eff(&"on_boop", &"heal", 2, &"self"), Fx.eff(&"on_play", &"draw", 1, &"own_hero")])
	assert_true(c.has_effect(&"on_boop") and not c.has_effect(&"on_destroyed"), "has_effect")
	assert_eq(c.effects_for(&"on_play").size(), 1, "effects_for")
	return true

func test_creature_state_clone_copies_new_fields() -> bool:
	var s: GameState = Fx.blank()
	var cr: GameState.CreatureState = Fx.put(s, 0, 1, Fx.card(&"t", CardData.Kind.CREATURE, 1, 1, 1))
	cr.gained = [&"guard"]; cr.hushed = true; cr.atk_bonus = 2; cr.hp_bonus = 3; cr.bubble = true
	cr.hidden = true; cr.second_wind_used = true; cr.attacks_used = 1; cr.booped = true; cr.ready = true
	var c2: GameState.CreatureState = s.clone().players[0].lanes[1].creature
	assert_eq(c2.gained, [&"guard"], "gained"); assert_true(c2.hushed and c2.bubble and c2.hidden, "flags")
	assert_eq([c2.atk_bonus, c2.hp_bonus, c2.attacks_used], [2, 3, 1], "numbers")
	assert_true(c2.second_wind_used and c2.booped and c2.ready, "more flags")
	c2.gained.append(&"venom")
	assert_eq(cr.gained, [&"guard"], "deep copy of gained")
	return true

func test_land_arrays_cover_neutral() -> bool:
	var n: int = CardData.Land.size()
	assert_eq(n, 5, "five lands incl. neutral")
	for arr: Array in [Palette.LAND_TOP, Palette.LAND_SIDE, Palette.LAND_CARD, VisualDB.ART_SKY, VisualDB.SPELL_GLOW, FxDirector.ELEMENT_BY_LAND]:
		assert_eq(arr.size(), n, "land array size")
	return true

func test_keyword_tables() -> bool:
	for k: StringName in Keywords.ORDER:
		assert_true(Keywords.NAMES.has(k) and Keywords.RULES.has(k), "tables have %s" % k)
	for k: StringName in [&"hush", &"dream_up", &"combo", &"spell_power"]:
		assert_true(Keywords.RULES.has(k), "rule text for %s" % k)
	return true
