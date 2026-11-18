extends TestCase
## Board look 2, spec 3.1: each deck shows its land's card back (from the user's backs_v4 designs).


func test_main_land_starters() -> bool:
	assert_eq(CardBacks.main_land(CardDB.deck(&"blaze_rush")), CardData.Land.EMBER, "Blaze Rush is an Ember deck")
	assert_eq(CardBacks.main_land(CardDB.deck(&"deep_freeze")), CardData.Land.FROST, "Deep Freeze is a Frost deck")
	assert_eq(CardBacks.main_land(CardDB.deck(&"grove_guard")), CardData.Land.MUSHROOM, "Grove Guard is a Mushroom deck")
	assert_eq(CardBacks.main_land(CardDB.deck(&"sugar_storm")), CardData.Land.CANDY, "Sugar Storm is a Candy deck")
	return true


func test_tie_uses_first_lane() -> bool:
	var d := DeckData.new()
	d.lands = [3, 1, 1, 3]
	d.cards = [CardDB.card(&"cinderpup"), CardDB.card(&"ashmite"), CardDB.card(&"iceling"), CardDB.card(&"snowmite"), CardDB.card(&"star_shard")]
	assert_eq(CardBacks.main_land(d), CardData.Land.FROST, "a tie goes to the first lane's land")
	d.lands = [1, 3, 3, 1]
	assert_eq(CardBacks.main_land(d), CardData.Land.EMBER, "a tie goes to the first lane's land (ember)")
	var neutral := DeckData.new()
	neutral.lands = [2, 2, 2, 2]
	neutral.cards = [CardDB.card(&"star_shard")]
	assert_eq(CardBacks.main_land(neutral), CardData.Land.CANDY, "no land cards: the first lane's land")
	return true


func test_texture_for() -> bool:
	assert_true(CardBacks.texture_for(CardDB.deck(&"blaze_rush")).resource_path.ends_with("card_backs/ember.png"), "ember back")
	assert_true(CardBacks.texture_for(CardDB.deck(&"sugar_storm")).resource_path.ends_with("card_backs/candy.png"), "candy back")
	for land: int in 4:
		assert_true(CardBacks.texture_for_land(land) != null, "land %d has a back" % land)
	return true


func test_rival_fan_uses_back() -> bool:
	var seat := RivalSeat.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(seat)
	await (Engine.get_main_loop() as SceneTree).process_frame
	seat.setup(MatchController.RIVAL_MODEL)
	var tex: Texture2D = CardBacks.texture_for_land(CardData.Land.FROST)
	seat.set_back(tex)
	assert_true(seat.hand_count() > 0, "the rival holds cards")
	assert_eq(seat.back_texture, tex, "the seat keeps the back")
	var faces: int = 0
	for mi: Node in seat.find_children("Back*", "MeshInstance3D", true, false):
		var mat := (mi as MeshInstance3D).material_override as ShaderMaterial
		if mat and mat.get_shader_parameter("albedo_tex") == tex:
			faces += 1
	assert_eq(faces, seat.hand_count() * 2, "every held card shows the back on both faces")
	seat.free()
	return true


func test_deck_piles_use_backs() -> bool:
	var stacks := CardStacks.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(stacks)
	await (Engine.get_main_loop() as SceneTree).process_frame
	var a: Texture2D = CardBacks.texture_for_land(CardData.Land.EMBER)
	var b: Texture2D = CardBacks.texture_for_land(CardData.Land.CANDY)
	stacks.set_backs(a, b)
	var decks: Array[int] = [20, 20]
	var discards: Array[int] = [0, 0]
	stacks.set_counts(decks, discards)
	assert_eq(stacks.deck_face_texture(0), a, "your deck pile shows your back")
	assert_eq(stacks.deck_face_texture(1), b, "the rival's deck pile shows theirs")
	stacks.free()
	return true
