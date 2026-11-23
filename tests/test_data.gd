extends TestCase
## Card data matches the Rules 2.0 spec (section 6) and the living board spec (section 10):
## numbers, keywords and generated text.

const WHENS: Array[StringName] = [&"on_play", &"on_boop", &"on_destroyed", &"after_damage", &"start_of_turn", &"end_of_turn", &"aura", &"on_level_up", &"field_aura", &"field_start", &"field_end", &"on_hurt"]
const OPS: Array[StringName] = [
	&"damage", &"heal", &"draw", &"freeze", &"gain_magic", &"hush", &"return_building", &"move", &"swap",
	&"dream_up", &"return_from_discard", &"lane_atk", &"lane_hp", &"lane_keyword", &"lane_damage_taken",
	&"opposing_atk", &"buff", &"give_keyword", &"destroy", &"armour", &"sprout_meadow", &"land_draw",
	&"on_land_atk", &"off_land_atk", &"on_land_hp", &"no_quirk",
	&"temp_atk", &"doom", &"grow_magic", &"bounce", &"spell_discount", &"transform",
]
const WHOS: Array[StringName] = [
	&"chosen_creature", &"chosen_own_creature", &"chosen_own_empty_lane", &"chosen_two_own_creatures",
	&"chosen_discard_creature", &"self", &"opposing", &"damaged_creature", &"lane_creature",
	&"all_enemy_creatures", &"all_own_creatures", &"enemy_hero", &"own_hero", &"same_target", &"own_on_land",
	&"chosen_enemy_creature", &"chosen_damaged_enemy", &"chosen_undamaged_creature", &"chosen_frozen_enemy", &"other_enemies",
	&"all_away_creatures",
]

## id: [level, cost, atk, hp, keywords, spell_power] (spec section 6; card expansion 2 spec 5).
const SPEC: Dictionary = {
	# Sunny Dunes and the second new-card batch (2026-11-23)
	&"sand_scuttler": [1, 1, 2, 3, [&"sturdy"], 0],
	&"meerkeep": [1, 2, 2, 3, [&"bask"], 0],
	&"sand_fox": [1, 2, 3, 2, [&"dash"], 0],
	&"sun_scarab": [1, 3, 3, 3, [], 0],
	&"dune_raptor": [2, 3, 3, 3, [], 0],
	&"sandwraith": [2, 4, 4, 4, [&"hidden", &"sturdy"], 0],
	&"oasis_alpaca": [2, 4, 3, 5, [&"bask"], 0],
	&"lamp_djinn": [3, 6, 6, 7, [], 1],
	&"sun_obelisk": [0, 2, 0, 0, [], 0],
	&"sandstone_watchtower": [0, 3, 0, 0, [], 0],
	&"sun_shield": [0, 2, 0, 0, [], 0],
	&"sandstorm": [0, 4, 0, 0, [], 0],
	&"mirage": [0, 1, 0, 0, [], 0],
	&"heatwave": [0, 3, 0, 0, [], 0],
	&"bog_toad": [1, 3, 2, 4, [&"sturdy"], 0],
	&"leaf_finch": [1, 2, 2, 2, [&"bask"], 0],
	&"moss_oracle": [2, 4, 3, 4, [], 0],
	&"seed_pod": [0, 1, 0, 0, [], 0],
	&"ember_wyrmling": [2, 3, 3, 3, [&"bask"], 0],
	&"magma_hog": [2, 4, 3, 5, [&"sturdy"], 0],
	&"spark_scroll": [0, 1, 0, 0, [], 0],
	&"kindle": [0, 2, 0, 0, [], 0],
	&"jelly_fish": [1, 2, 2, 2, [&"bubble"], 0],
	&"taffy_serpent": [1, 3, 2, 5, [&"sturdy"], 0],
	&"cotton_sheep": [2, 4, 3, 4, [&"bask"], 0],
	&"lucky_wrapper": [0, 1, 0, 0, [], 0],
	&"snow_wolf": [1, 3, 3, 2, [&"dash"], 0],
	&"snow_globe": [0, 1, 0, 0, [], 0],
	&"ice_armor": [0, 2, 0, 0, [], 0],
	&"frost_cairn": [0, 2, 0, 0, [], 0],
	# Card expansion 2
	&"glowmoth": [1, 2, 2, 1, [&"hidden"], 0], &"sporemoth": [1, 4, 4, 3, [&"venom", &"hidden"], 0],
	&"barkbeetle": [1, 3, 3, 3, [], 0], &"mossback_colossus": [1, 5, 4, 8, [&"guard"], 0],
	&"pain_shroom": [1, 3, 1, 4, [], 0], &"fairy_ring": [0, 2, 0, 0, [], 0], &"deep_roots": [0, 2, 0, 0, [], 0],
	&"bark_coat": [0, 2, 0, 0, [], 0], &"thorn_lash": [0, 4, 0, 0, [], 0], &"grove_roar": [0, 3, 0, 0, [], 0],
	&"emberkit": [1, 2, 2, 2, [], 0], &"twinflame_hound": [1, 3, 4, 3, [&"dash"], 0],
	&"cinder_wisp": [1, 2, 1, 3, [], 0], &"magma_wraith": [2, 6, 5, 6, [], 0], &"hot_head": [1, 1, 3, 2, [], 0],
	&"bellows_forge": [0, 2, 0, 0, [], 0], &"stoke": [0, 0, 0, 0, [], 0], &"overheat": [0, 1, 0, 0, [], 0],
	&"finish_off": [0, 2, 0, 0, [], 0], &"ember_pact": [0, 1, 0, 0, [], 0],
	&"gummy_cub": [1, 1, 1, 3, [], 0], &"gummy_goliath": [1, 3, 4, 7, [], 0],
	&"cotton_puff": [1, 2, 2, 2, [&"bubble"], 0], &"candyfloss_bat": [1, 5, 4, 5, [&"bubble", &"flurry"], 0],
	&"sugar_smuggler": [1, 2, 2, 2, [&"hidden"], 0], &"gingerbread_gate": [0, 2, 0, 0, [], 0],
	&"taffy_pull": [0, 2, 0, 0, [], 0], &"sugar_shiv": [0, 1, 0, 0, [], 0], &"jawbreaker": [0, 2, 0, 0, [], 0],
	&"sugar_high": [0, 0, 0, 0, [], 0],
	&"frostwisp": [1, 2, 1, 3, [], 0], &"glacial_wisp": [1, 4, 3, 5, [&"bubble"], 0],
	&"snow_pup": [1, 2, 2, 3, [], 0], &"snowfang_alpha": [1, 6, 5, 5, [], 0], &"ice_sage": [1, 3, 2, 4, [], 1],
	&"frost_lookout": [0, 4, 0, 0, [], 0], &"crack_the_ice": [0, 1, 0, 0, [], 0], &"whiteout": [0, 3, 0, 0, [], 0],
	&"icicle": [0, 1, 0, 0, [], 0], &"snowmanify": [0, 4, 0, 0, [], 0], &"snowman": [1, 1, 1, 1, [], 0],
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
	&"gumdrop": [1, 2, 2, 4, [], 0], &"taffy_snail": [1, 2, 3, 4, [], 0],
	&"lollibat": [1, 3, 2, 4, [&"flurry"], 0], &"sugar_sprite": [2, 3, 3, 3, [&"hidden"], 0],
	&"jellywobble": [2, 4, 4, 6, [], 0], &"bonbon_behemoth": [3, 6, 6, 7, [], 0],
	&"sugar_shack": [0, 1, 0, 0, [], 0], &"candy_mill": [0, 2, 0, 0, [], 0],
	&"sugar_rush": [0, 1, 0, 0, [], 0], &"swap_trick": [0, 1, 0, 0, [], 0],
	&"snowmite": [1, 2, 1, 3, [], 0], &"iceling": [1, 2, 2, 3, [&"bubble"], 0],
	&"frostfang": [1, 3, 3, 3, [], 0], &"glacier_tortoise": [2, 3, 3, 6, [&"bubble"], 0],
	&"rimewing": [2, 4, 4, 4, [], 0], &"blizzard_titan": [3, 7, 6, 8, [&"bubble"], 0],
	&"ice_wall": [0, 2, 0, 0, [], 0], &"frost_spire": [0, 2, 0, 0, [], 0],
	&"cold_snap": [0, 1, 0, 0, [], 0], &"avalanche": [0, 3, 0, 0, [], 0],
	&"star_shard": [0, 0, 0, 0, [], 0],
	&"volcano": [0, 4, 0, 0, [], 0], &"snowstorm": [0, 4, 0, 0, [], 0],
	&"spore_bloom": [0, 3, 0, 0, [], 0], &"sugar_rain": [0, 3, 0, 0, [], 0],
	&"bark_shield": [0, 1, 0, 0, [], 0], &"candy_shell": [0, 2, 0, 0, [], 0],
}

## Rules text, verbatim from spec section 6.
const SPEC_TEXT: Dictionary = {
	# Sunny Dunes and the second new-card batch (2026-11-23)
	&"sand_scuttler": "Sturdy.",
	&"meerkeep": "Bask. Boop: Gain 1 armour.",
	&"sand_fox": "Dash.",
	&"sun_scarab": "On play: Gain 2 armour.",
	&"dune_raptor": "On play: Dream Up a Sunny Dunes card.",
	&"sandwraith": "Hidden. Sturdy.",
	&"oasis_alpaca": "Bask. End of your turn: Heal your hero 2.",
	&"lamp_djinn": "Spell Power +1. On play: Dream Up a spell.",
	&"sun_obelisk": "The creature in this lane has Sturdy and +1 ATK.",
	&"sandstone_watchtower": "Start of your turn: Gain 2 armour.",
	&"sun_shield": "Give one of your creatures +2/+2 and give it Sturdy.",
	&"sandstorm": "Deal 2 damage to every creature that isn't at home.",
	&"mirage": "Dream Up a creature.",
	&"heatwave": "Field. End of each turn: Deal 1 damage to every creature that isn't at home.",
	&"bog_toad": "Sturdy.",
	&"leaf_finch": "Bask.",
	&"moss_oracle": "On play: Dream Up a spell.",
	&"seed_pod": "Dream Up a Mushroom Forest card.",
	&"ember_wyrmling": "Bask.",
	&"magma_hog": "Sturdy.",
	&"spark_scroll": "Dream Up an Ember Flats card.",
	&"kindle": "Deal 3 damage to a creature. Combo: Dream Up an Ember Flats card.",
	&"jelly_fish": "Bubble.",
	&"taffy_serpent": "Sturdy.",
	&"cotton_sheep": "Bask.",
	&"lucky_wrapper": "Dream Up a Candy Hills card.",
	&"snow_wolf": "Dash.",
	&"snow_globe": "Dream Up a Frostpeak card.",
	&"ice_armor": "Give one of your creatures +0/+3 and give it Sturdy.",
	&"frost_cairn": "The opposing creature has −1 ATK (minimum 0).",
	# Card expansion 2
	&"glowmoth": "Hidden. Merges with Sporeling.",
	&"sporemoth": "Merged form of Glowmoth + Sporeling. Venom. Hidden. Boop: Heal this creature 2. Level up: Heal your hero 2.",
	&"barkbeetle": "On play: Give all your creatures +0/+1. Merges with Mossback.",
	&"mossback_colossus": "Merged form of Barkbeetle + Mossback. Guard. When merged: Gain 2 armour. Give all your creatures +0/+1.",
	&"pain_shroom": "After this takes damage, draw a card.",
	&"fairy_ring": "The creature in this lane has Leech.",
	&"deep_roots": "Gain 1 max magic.",
	&"bark_coat": "Give a creature +2/+2 and give it Guard.",
	&"thorn_lash": "Deal 4 damage to an enemy creature. Deal 1 damage to every other enemy.",
	&"grove_roar": "Give all your creatures +2 ATK this turn.",
	&"emberkit": "After this takes damage, give this creature +1/+0. Merges with Cinderpup.",
	&"twinflame_hound": "Merged form of Emberkit + Cinderpup. Dash. When merged: Give this creature +1/+1. After this takes damage, give this creature +1/+0. Level up: Give this creature Flurry.",
	&"cinder_wisp": "Boop: Deal 1 damage to an enemy creature. Merges with Magmaw.",
	&"magma_wraith": "Merged form of Magmaw + Cinder Wisp. Boop: Deal 1 damage to an enemy creature. Deal 2 damage to the enemy hero.",
	&"hot_head": "On play: Deal 2 damage to your hero.",
	&"bellows_forge": "Start of your turn: Deal 1 damage to the creature in this lane and give it +2/+0.",
	&"stoke": "Deal 1 damage to one of your creatures and give it +2/+0.",
	&"overheat": "Give one of your creatures +4/+4 and destroy it at the end of your turn.",
	&"finish_off": "Destroy a damaged enemy creature.",
	&"ember_pact": "Deal 3 damage to your hero. Draw 2 cards.",
	&"gummy_cub": "On play, if you control another Blob: Draw a card. Merges with Gumdrop.",
	&"gummy_goliath": "Merged form of Gumdrop + Gummy Cub. When merged: Draw a card. Boop: Draw a card.",
	&"cotton_puff": "Bubble. Merges with Lollibat.",
	&"candyfloss_bat": "Merged form of Lollibat + Cotton Puff. Bubble. Flurry. Boop: Move this creature to one of your empty lanes.",
	&"sugar_smuggler": "Hidden. On play, Combo: Draw a card.",
	&"gingerbread_gate": "The creature in this lane has Guard and +2 HP.",
	&"taffy_pull": "Return an enemy creature to its owner's hand.",
	&"sugar_shiv": "Deal 2 damage to an undamaged creature.",
	&"jawbreaker": "Deal 2 damage to a creature. Combo: deal 2 more damage to it.",
	&"sugar_high": "Your next spell this turn costs 2 less.",
	&"frostwisp": "Boop: Freeze an enemy creature. Merges with Iceling.",
	&"glacial_wisp": "Merged form of Frostwisp + Iceling. Bubble. Boop: Freeze an enemy creature. Level up: Give this creature Bubble.",
	&"snow_pup": "On play: Freeze the opposing creature. Merges with Frostfang.",
	&"snowfang_alpha": "Merged form of Frostfang + Snow Pup. When merged: Freeze the opposing creature. After this damages a creature, freeze it.",
	&"ice_sage": "Spell Power +1.",
	&"frost_lookout": "End of your turn: Freeze the opposing creature.",
	&"crack_the_ice": "Destroy a frozen enemy creature.",
	&"whiteout": "Freeze all enemy creatures.",
	&"icicle": "Freeze a creature. If it was already frozen, deal 4 damage to it instead.",
	&"snowmanify": "Turn a creature into a 1/1 Snowman with no abilities.",
	&"snowman": "",
	&"sporeling": "Venom. Boop: Heal this creature 2. Level up: Heal your hero 2. Merges with Glowmoth.",
	&"mossback": "Guard. On play: Gain 2 armour. Merges with Barkbeetle.",
	&"puffcap": "Second Wind. Boop: Heal your hero 2.",
	&"glimmer_morel": "Boop: Heal all your creatures 2. On play, if you control another Sprout: Gain 3 armour.",
	&"rootstalker": "Leech. On play: Heal your hero 2.",
	&"elder_shroomhulk": "Guard. Second Wind. Boop: Heal all your creatures 3.",
	&"spore_hut": "Start of your turn: Heal the creature in this lane 2.",
	&"glowcap_lantern": "The creature in this lane has +2 HP and Guard.",
	&"rain_of_spores": "Heal one of your creatures 4.",
	&"regrowth": "Return a creature from your discard pile to your hand.",
	&"cinderpup": "Dash. On play, if you control another Beast: Give this creature +1/+1. Level up: Give this creature Flurry. Merges with Emberkit.",
	&"ashmite": "Spell Power +1. Boop: Deal 1 damage to the opposing creature.",
	&"flarebeak": "Dash. Level up: Deal 1 damage to the enemy hero.",
	&"magmaw": "Boop: Deal 2 damage to the enemy hero. Merges with Cinder Wisp.",
	&"blazehorn": "Dash. On play: Deal 2 damage to the opposing creature.",
	&"inferno_drake": "Spell Power +1. Boop: Deal 2 damage to all enemy creatures.",
	&"kiln_tower": "The creature in this lane has +2 ATK.",
	&"smokestack": "End of your turn: Deal 1 damage to the enemy hero.",
	&"fireball": "Deal 3 damage to a creature.",
	&"ember_rain": "Deal 2 damage to all enemy creatures.",
	&"gumdrop": "Boop: Draw a card. Merges with Gummy Cub.",
	&"taffy_snail": "On play: Gain 1 magic. On play, if you control 2 other Blobs: Gain 1 magic.",
	&"lollibat": "Flurry. Boop: Move this creature to one of your empty lanes. Merges with Cotton Puff.",
	&"sugar_sprite": "Hidden. On play, Combo: Return the opposing building to its owner's hand. Level up: Draw a card.",
	&"jellywobble": "When destroyed: Draw 2 cards.",
	&"bonbon_behemoth": "On play: Dream Up a Candy Hills card. Boop: Draw 2 cards.",
	&"sugar_shack": "The creature in this lane has +1 ATK and +1 HP.",
	&"candy_mill": "Start of your turn: Gain 1 magic.",
	&"sugar_rush": "Draw 2 cards.",
	&"swap_trick": "Swap two of your creatures between lanes. Combo: Draw a card.",
	&"snowmite": "Boop: Freeze the opposing creature. Level up: Freeze the opposing creature.",
	&"iceling": "Bubble. Level up: Give this creature Bubble. Merges with Frostwisp.",
	&"frostfang": "After this damages a creature, freeze it. Merges with Snow Pup.",
	&"glacier_tortoise": "Bubble. On play: Gain 3 armour.",
	&"rimewing": "On play: Hush the opposing creature. On play, if you control another Flyer: Draw a card.",
	&"blizzard_titan": "Bubble. Boop: Freeze all enemy creatures.",
	&"ice_wall": "The creature in this lane takes 1 less damage from attacks and hit-back (minimum 1).",
	&"frost_spire": "The opposing creature has −1 ATK (minimum 0).",
	&"cold_snap": "Freeze a creature. Draw a card.",
	&"avalanche": "Deal 3 damage to a creature and freeze it.",
	&"star_shard": "Gain 1 magic.",
	&"volcano": "Field. Creatures on Ember Flats have +1 ATK. End of each turn: Deal 1 damage to that player's creatures on Frostpeak.",
	&"snowstorm": "Field. Creatures not on Frostpeak have −1 ATK. Ember Flats give no home bonus.",
	&"spore_bloom": "Field. Start of each turn: That player's first Meadow lane grows into Mushroom Forest. Creatures on Mushroom Forest have +1 HP.",
	&"sugar_rain": "Field. Start of each turn: If that player has a creature on Candy Hills, they draw a card.",
	&"bark_shield": "Gain 4 armour.",
	&"candy_shell": "Gain 3 armour. Draw a card.",
}


func test_card_count() -> bool:
	var cards: Array[CardData] = CardDB.all_cards()
	assert_eq(cards.size(), 118, "118 cards (47 + card expansion 2's 41 + Sunny Dunes 14 + 16 more)")
	assert_eq(CardDB.collectible_cards().size(), 109, "109 collectible")
	# 10 per land from Rules 2.0, each land's field spell, the two armour spells, then expansion 2 (10 per land,
	# Frost 11 with the Snowman token), then 4 per land and Sunny Dunes' 14.
	var per_land: Dictionary = {0: 26, 1: 25, 2: 26, 3: 26, 5: 14}
	for land: int in per_land:
		assert_eq(cards.filter(func(c: CardData) -> bool: return c.land == land).size(), per_land[land], "%d cards for land %d" % [per_land[land], land])
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
		if c.is_creature() and c.collectible:
			var band: Array = [[], [1, 3], [3, 5], [6, 8]][c.level]
			assert_true(c.cost >= band[0] and c.cost <= band[1], "%s cost in level band" % c.id)
			assert_true(c.attack >= 0 and c.health > 0, "%s stats" % c.id)
		elif not c.is_creature():
			assert_eq(c.level, 0, "%s non-creature level 0" % c.id)
			# Expansion 2 has 0-cost trade-off spells (Stoke, Sugar Shiv, Sugar High).
			assert_true(c.cost >= 0 and c.cost <= 5, "%s cost 0-5" % c.id)
	return true


func test_decks() -> bool:
	var decks: Array[DeckData] = CardDB.all_decks()
	assert_eq(decks.size(), 5, "5 decks")
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
