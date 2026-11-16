extends TestCase

func _c(kind: CardData.Kind, kws: Array[StringName], effs: Array[EffectData], sp: int = 0) -> CardData:
	var c: CardData = Fx.card(&"t", kind, 1, 1, 1, kws, effs)
	c.spell_power = sp
	return c

func test_keywords_and_boop() -> bool:
	assert_eq(CardText.render(_c(CardData.Kind.CREATURE, [&"second_wind", &"guard"], [Fx.eff(&"on_boop", &"heal", 3, &"all_own_creatures")])),
		"Guard. Second Wind. Boop: Heal all your creatures 3.", "order + boop")
	return true

func test_spell_power_line() -> bool:
	assert_eq(CardText.render(_c(CardData.Kind.CREATURE, [], [Fx.eff(&"on_boop", &"damage", 1, &"opposing")], 1)),
		"Spell Power +1. Boop: Deal 1 damage to the opposing creature.", "spell power")
	return true

func test_same_target_join() -> bool:
	assert_eq(CardText.render(_c(CardData.Kind.SPELL, [], [Fx.eff(&"on_play", &"damage", 3, &"chosen_creature"), Fx.eff(&"on_play", &"freeze", 0, &"same_target")])),
		"Deal 3 damage to a creature and freeze it.", "avalanche")
	return true

func test_spell_two_sentences_and_combo() -> bool:
	assert_eq(CardText.render(_c(CardData.Kind.SPELL, [], [Fx.eff(&"on_play", &"swap", 0, &"chosen_two_own_creatures"), Fx.eff(&"on_play", &"draw", 1, &"own_hero", {"combo": true})])),
		"Swap two of your creatures between lanes. Combo: Draw a card.", "swap trick")
	assert_eq(CardText.render(_c(CardData.Kind.CREATURE, [&"hidden"], [Fx.eff(&"on_play", &"return_building", 0, &"opposing", {"combo": true})])),
		"Hidden. On play, Combo: Return the opposing building to its owner's hand.", "sugar sprite")
	return true

func test_auras_merge() -> bool:
	assert_eq(CardText.render(_c(CardData.Kind.BUILDING, [], [Fx.eff(&"aura", &"lane_hp", 2, &"lane_creature"), Fx.eff(&"aura", &"lane_keyword", 0, &"lane_creature", {"keyword": &"guard"})])),
		"The creature in this lane has +2 HP and Guard.", "glowcap")
	return true

func test_after_damage_and_dream_up() -> bool:
	assert_eq(CardText.render(_c(CardData.Kind.CREATURE, [], [Fx.eff(&"after_damage", &"freeze", 0, &"damaged_creature")])),
		"After this damages a creature, freeze it.", "frostfang")
	assert_eq(CardText.render(_c(CardData.Kind.CREATURE, [], [Fx.eff(&"on_play", &"dream_up", 0, &"own_hero", {"filter_land": CardData.Land.CANDY})])),
		"On play: Dream Up a Candy Hills card.", "dream up")
	return true

func test_bbcode_and_tooltip() -> bool:
	var c: CardData = _c(CardData.Kind.CREATURE, [&"guard"], [])
	assert_eq(CardText.render_bbcode(c), "[b]Guard[/b].", "bold keyword")
	assert_eq(CardText.tooltip(c), "Guard: " + Keywords.RULES[&"guard"], "tooltip")
	assert_eq(CardText.tooltip(_c(CardData.Kind.CREATURE, [], [])), "", "no tooltip")
	return true
