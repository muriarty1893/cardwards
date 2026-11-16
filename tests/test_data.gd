extends TestCase
## Card data matches the Rules 2.0 spec (section 6): numbers, keywords and generated text.

const WHENS: Array[StringName] = [&"on_play", &"on_boop", &"on_destroyed", &"after_damage", &"start_of_turn", &"end_of_turn", &"aura"]
const OPS: Array[StringName] = [
	&"damage", &"heal", &"draw", &"freeze", &"gain_magic", &"hush", &"return_building", &"move", &"swap",
	&"dream_up", &"return_from_discard", &"lane_atk", &"lane_hp", &"lane_keyword", &"lane_damage_taken",
	&"opposing_atk", &"buff", &"give_keyword", &"destroy",
]
const WHOS: Array[StringName] = [
	&"chosen_creature", &"chosen_own_creature", &"chosen_own_empty_lane", &"chosen_two_own_creatures",
	&"chosen_discard_creature", &"self", &"opposing", &"damaged_creature", &"lane_creature",
	&"all_enemy_creatures", &"all_own_creatures", &"enemy_hero", &"own_hero", &"same_target",
]

## id: [level, cost, atk, hp, keywords, spell_power] (spec section 6).
const SPEC: Dictionary = {
	&"sporeling": [1, 2, 1, 2, [&"venom"], 0], &"mossback": [1, 2, 1, 5, [&"guard"], 0],
	&"puffcap": [1, 3, 2, 3, [&"second_wind"], 0], &"glimmer_morel": [2, 3, 3, 4, [], 0],
	&"rootstalker": [2, 4, 3, 5, [&"leech"], 0], &"elder_shroomhulk": [3, 7, 5, 8, [&"guard", &"second_wind"], 0],
	&"spore_hut": [0, 2, 0, 0, [], 0], &"glowcap_lantern": [0, 3, 0, 0, [], 0],
	&"rain_of_spores": [0, 1, 0, 0, [], 0], &"regrowth": [0, 2, 0, 0, [], 0],
	&"cinderpup": [1, 1, 2, 1, [&"dash"], 0], &"ashmite": [1, 2, 2, 2, [], 1],
	&"flarebeak": [1, 3, 3, 3, [&"dash"], 0], &"magmaw": [2, 4, 4, 4, [], 0],
	&"blazehorn": [2, 5, 5, 4, [&"dash"], 0], &"inferno_drake": [3, 7, 6, 6, [], 1],
	&"kiln_tower": [0, 2, 0, 0, [], 0], &"smokestack": [0, 2, 0, 0, [], 0],
	&"fireball": [0, 2, 0, 0, [], 0], &"ember_rain": [0, 4, 0, 0, [], 0],
	&"gumdrop": [1, 2, 1, 3, [], 0], &"taffy_snail": [1, 2, 1, 4, [], 0],
	&"lollibat": [1, 3, 2, 3, [&"flurry"], 0], &"sugar_sprite": [2, 3, 3, 2, [&"hidden"], 0],
	&"jellywobble": [2, 4, 3, 5, [], 0], &"bonbon_behemoth": [3, 7, 5, 7, [], 0],
	&"sugar_shack": [0, 1, 0, 0, [], 0], &"candy_mill": [0, 3, 0, 0, [], 0],
	&"sugar_rush": [0, 2, 0, 0, [], 0], &"swap_trick": [0, 1, 0, 0, [], 0],
	&"snowmite": [1, 2, 1, 3, [], 0], &"iceling": [1, 2, 2, 2, [&"bubble"], 0],
	&"frostfang": [1, 3, 3, 3, [], 0], &"glacier_tortoise": [2, 3, 2, 6, [&"bubble"], 0],
	&"rimewing": [2, 4, 3, 4, [], 0], &"blizzard_titan": [3, 8, 6, 8, [&"bubble"], 0],
	&"ice_wall": [0, 2, 0, 0, [], 0], &"frost_spire": [0, 2, 0, 0, [], 0],
	&"cold_snap": [0, 1, 0, 0, [], 0], &"avalanche": [0, 3, 0, 0, [], 0],
	&"star_shard": [0, 0, 0, 0, [], 0],
}

## Rules text, verbatim from spec section 6.
const SPEC_TEXT: Dictionary = {
	&"sporeling": "Venom. Boop: Heal this creature 2.",
	&"mossback": "Guard.",
	&"puffcap": "Second Wind. Boop: Heal your hero 2.",
	&"glimmer_morel": "Boop: Heal all your creatures 2.",
	&"rootstalker": "Leech. On play: Heal your hero 2.",
	&"elder_shroomhulk": "Guard. Second Wind. Boop: Heal all your creatures 3.",
	&"spore_hut": "Start of your turn: Heal the creature in this lane 2.",
	&"glowcap_lantern": "The creature in this lane has +2 HP and Guard.",
	&"rain_of_spores": "Heal one of your creatures 4.",
	&"regrowth": "Return a creature from your discard pile to your hand.",
	&"cinderpup": "Dash.",
	&"ashmite": "Spell Power +1. Boop: Deal 1 damage to the opposing creature.",
	&"flarebeak": "Dash.",
	&"magmaw": "Boop: Deal 2 damage to the enemy hero.",
	&"blazehorn": "Dash. On play: Deal 2 damage to the opposing creature.",
	&"inferno_drake": "Spell Power +1. Boop: Deal 2 damage to all enemy creatures.",
	&"kiln_tower": "The creature in this lane has +2 ATK.",
	&"smokestack": "End of your turn: Deal 1 damage to the enemy hero.",
	&"fireball": "Deal 3 damage to a creature.",
	&"ember_rain": "Deal 2 damage to all enemy creatures.",
	&"gumdrop": "Boop: Draw a card.",
	&"taffy_snail": "On play: Gain 1 magic.",
	&"lollibat": "Flurry. Boop: Move this creature to one of your empty lanes.",
	&"sugar_sprite": "Hidden. On play, Combo: Return the opposing building to its owner's hand.",
	&"jellywobble": "When destroyed: Draw 2 cards.",
	&"bonbon_behemoth": "On play: Dream Up a Candy Hills card. Boop: Draw 2 cards.",
	&"sugar_shack": "The creature in this lane has +1 ATK and +1 HP.",
	&"candy_mill": "Start of your turn: Gain 1 magic.",
	&"sugar_rush": "Draw 2 cards.",
	&"swap_trick": "Swap two of your creatures between lanes. Combo: Draw a card.",
	&"snowmite": "Boop: Freeze the opposing creature.",
	&"iceling": "Bubble.",
	&"frostfang": "After this damages a creature, freeze it.",
	&"glacier_tortoise": "Bubble.",
	&"rimewing": "On play: Hush the opposing creature.",
	&"blizzard_titan": "Bubble. Boop: Freeze all enemy creatures.",
	&"ice_wall": "The creature in this lane takes 1 less damage from attacks and hit-back (minimum 1).",
	&"frost_spire": "The opposing creature has −1 ATK (minimum 0).",
	&"cold_snap": "Freeze a creature. Draw a card.",
	&"avalanche": "Deal 3 damage to a creature and freeze it.",
	&"star_shard": "Gain 1 magic.",
}


func test_card_count() -> bool:
	var cards: Array[CardData] = CardDB.all_cards()
	assert_eq(cards.size(), 41, "41 cards")
	for land: int in 4:
		assert_eq(cards.filter(func(c: CardData) -> bool: return c.land == land).size(), 10, "10 cards for land %d" % land)
	var neutral: Array = cards.filter(func(c: CardData) -> bool: return c.land == CardData.Land.NEUTRAL)
	assert_eq(neutral.size(), 1, "one neutral card")
	assert_eq((neutral[0] as CardData).id, &"star_shard", "star shard")
	return true


func test_spec_numbers() -> bool:
	for c: CardData in CardDB.all_cards():
		assert_true(SPEC.has(c.id), "%s in spec" % c.id)
		var v: Array = SPEC.get(c.id, [])
		if v.is_empty():
			continue
		assert_eq([c.level, c.cost, c.attack, c.health], [v[0], v[1], v[2], v[3]], "%s numbers" % c.id)
		var kws: Array[StringName] = []
		kws.assign(v[4])
		assert_eq(c.keywords, kws, "%s keywords" % c.id)
		assert_eq(c.spell_power, v[5], "%s spell power" % c.id)
	return true


func test_generated_text_matches_spec() -> bool:
	for c: CardData in CardDB.all_cards():
		assert_eq(CardText.render(c), SPEC_TEXT.get(c.id, "?"), "%s text" % c.id)
	return true


func test_cards_validate() -> bool:
	for c: CardData in CardDB.all_cards():
		for k: StringName in c.keywords:
			assert_true(k in Keywords.ORDER, "%s keyword %s" % [c.id, k])
		for e: EffectData in c.effects:
			assert_true(e.when in WHENS and e.op in OPS and e.who in WHOS, "%s effect %s/%s/%s" % [c.id, e.when, e.op, e.who])
		if c.is_creature():
			var band: Array = [[], [1, 3], [3, 5], [6, 8]][c.level]
			assert_true(c.cost >= band[0] and c.cost <= band[1], "%s cost in level band" % c.id)
			assert_true(c.attack >= 0 and c.health > 0, "%s stats" % c.id)
		else:
			assert_eq(c.level, 0, "%s non-creature level 0" % c.id)
			assert_true(c.cost >= 1 and c.cost <= 5 or c.id == &"star_shard", "%s cost 1-5" % c.id)
	return true


func test_decks() -> bool:
	var decks: Array[DeckData] = CardDB.all_decks()
	assert_eq(decks.size(), 4, "4 decks")
	for d: DeckData in decks:
		assert_eq(d.cards.size(), 30, "%s 30 cards" % d.id)
		assert_eq(d.lands.size(), 4, "%s 4 lands" % d.id)
		var main_land: int = d.lands[0]
		for c: CardData in d.cards:
			assert_true(c.id != &"star_shard", "%s has no star shard" % d.id)
			if c.land != main_land:
				assert_true(c.level <= 1, "%s splash card %s level <= 1" % [d.id, c.id])
	var br: DeckData = CardDB.deck(&"blaze_rush")
	assert_eq(br.lands, [CardData.Land.EMBER, CardData.Land.EMBER, CardData.Land.CANDY, CardData.Land.EMBER], "blaze_rush lands")
	return true
