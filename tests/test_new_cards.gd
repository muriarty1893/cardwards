extends TestCase
## Card expansion 2, spec 5: the 41 new cards load, read right, merge in pairs and have visuals.

const NEW_COLLECTIBLE: Array[StringName] = [
	&"glowmoth", &"barkbeetle", &"pain_shroom", &"fairy_ring", &"deep_roots", &"bark_coat", &"thorn_lash", &"grove_roar",
	&"emberkit", &"cinder_wisp", &"hot_head", &"bellows_forge", &"stoke", &"overheat", &"finish_off", &"ember_pact",
	&"gummy_cub", &"cotton_puff", &"sugar_smuggler", &"gingerbread_gate", &"taffy_pull", &"sugar_shiv", &"jawbreaker", &"sugar_high",
	&"frostwisp", &"snow_pup", &"ice_sage", &"frost_lookout", &"crack_the_ice", &"whiteout", &"icicle", &"snowmanify",
]
const MERGED: Array[StringName] = [
	&"sporemoth", &"mossback_colossus", &"twinflame_hound", &"magma_wraith",
	&"gummy_goliath", &"candyfloss_bat", &"glacial_wisp", &"snowfang_alpha",
]
## [existing partner, new partner, merged form, attack, health]
const PAIRS: Array[Array] = [
	[&"sporeling", &"glowmoth", &"sporemoth", 4, 3], [&"mossback", &"barkbeetle", &"mossback_colossus", 4, 8],
	[&"cinderpup", &"emberkit", &"twinflame_hound", 4, 3], [&"magmaw", &"cinder_wisp", &"magma_wraith", 5, 6],
	[&"gumdrop", &"gummy_cub", &"gummy_goliath", 4, 7], [&"lollibat", &"cotton_puff", &"candyfloss_bat", 4, 5],
	[&"iceling", &"frostwisp", &"glacial_wisp", 3, 5], [&"frostfang", &"snow_pup", &"snowfang_alpha", 5, 5],
]


func test_new_cards_load() -> bool:
	for id: StringName in NEW_COLLECTIBLE:
		assert_true(CardDB.has_card(id), "%s exists" % id)
		if CardDB.has_card(id):
			assert_true(CardDB.card(id).collectible, "%s is collectible" % id)
	for id: StringName in MERGED + [&"snowman"]:
		assert_true(CardDB.has_card(id), "%s exists" % id)
		if CardDB.has_card(id):
			assert_true(not CardDB.card(id).collectible, "%s is not collectible" % id)
	assert_eq(CardDB.collectible_cards().size(), 47 + 32 + 30 + 73 + 18, "200 collectible cards (Dark Moon adds 73, Legends & Grudges 18)")
	return true


func test_pairs() -> bool:
	for pr: Array in PAIRS:
		var a: CardData = CardDB.card(pr[0])
		var b: CardData = CardDB.card(pr[1])
		var m: CardData = CardDB.card(pr[2])
		assert_eq(a.merge_with, b.id, "%s merges with %s" % [a.id, b.id])
		assert_eq(b.merge_with, a.id, "%s merges with %s" % [b.id, a.id])
		assert_eq(a.merges_into, m.id, "%s merges into %s" % [a.id, m.id])
		assert_eq(b.merges_into, m.id, "%s merges into %s" % [b.id, m.id])
		assert_eq(Vector2i(m.attack, m.health), Vector2i(pr[3], pr[4]), "%s stats" % m.id)
		assert_eq(m.land, a.land, "%s is the partners' land" % m.id)
	return true


func test_texts() -> bool:
	var want: Dictionary = {
		&"stoke": "Deal 1 damage to one of your creatures and give it +2/+0.",
		&"overheat": "Give one of your creatures +4/+4 and destroy it at the end of your turn.",
		&"finish_off": "Destroy a damaged enemy creature.",
		&"deep_roots": "Gain 1 max magic.",
		&"thorn_lash": "Deal 4 damage to an enemy creature. Deal 1 damage to every other enemy.",
		&"grove_roar": "Give all your creatures +2 ATK this turn.",
		&"taffy_pull": "Return an enemy creature to its owner's hand.",
		&"sugar_shiv": "Deal 2 damage to an undamaged creature.",
		&"jawbreaker": "Deal 2 damage to a creature. Combo: deal 2 more damage to it.",
		&"sugar_high": "Your next spell this turn costs 2 less.",
		&"crack_the_ice": "Destroy a frozen enemy creature.",
		&"whiteout": "Freeze all enemy creatures.",
		&"icicle": "Freeze a creature. If it was already frozen, deal 4 damage to it instead.",
		&"snowmanify": "Turn a creature into a 1/1 Snowman with no abilities.",
	}
	for id: StringName in want:
		assert_eq(CardText.render(CardDB.card(id)), want[id], "%s text" % id)
	assert_true(CardText.render(CardDB.card(&"emberkit")).contains("After this takes damage"), "on_hurt prefix")
	assert_true(CardText.render(CardDB.card(&"sporeling")).ends_with("Merges with Glowmoth."), "old partner gets the merge line")
	assert_true(CardText.render(CardDB.card(&"magma_wraith")).begins_with("Merged form of Magmaw + Cinder Wisp."), "merged form text")
	return true


func test_visuals() -> bool:
	for id: StringName in NEW_COLLECTIBLE + MERGED + [&"snowman"]:
		var c: CardData = CardDB.card(id)
		assert_true(VisualDB.ENTRIES.has(id), "%s has a visual entry" % id)
		if c.kind == CardData.Kind.SPELL:
			assert_true(VisualDB.SPELL_ICONS.has(id) and ResourceLoader.exists(VisualDB.SPELL_ICONS[id]), "%s has a spell icon" % id)
		else:
			assert_true(ResourceLoader.exists(VisualDB.model_path(id)), "%s has a model (%s)" % [id, VisualDB.model_path(id)])
	return true


func test_on_hurt_trigger() -> bool:
	var s: GameState = Fx.blank()
	Fx.fill_deck(s, 0, &"star_shard", 3)
	Fx.put_creature(s, 0, 0, &"pain_shroom")
	Fx.put_creature(s, 0, 1, &"emberkit")
	var ev: Array[GameEvent] = []
	var hand: int = s.players[0].hand.size()
	Rules.damage_creature(s, 0, 0, 1, {"player": 1, "lane": -1, "kind": &"spell"}, ev)
	assert_eq(s.players[0].hand.size(), hand + 1, "Pain Shroom draws when hurt")
	var atk: int = Rules.effective_attack(s, 0, 1)
	Rules.damage_creature(s, 0, 1, 1, {"player": 1, "lane": -1, "kind": &"spell"}, ev)
	assert_eq(Rules.effective_attack(s, 0, 1), atk + 1, "Emberkit grows when hurt")
	return true
