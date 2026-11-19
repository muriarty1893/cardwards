extends TestCase
## The online version string: both games must have the same cards and the same rules code.


func test_rules_stamp_is_current() -> bool:
	assert_eq(RulesStamp.HASH, NetVersion.rules_source_hash(), "run tools/stamp_rules.gd after changing core/")
	return true


func test_version_format_and_card_sensitivity() -> bool:
	var v: String = NetVersion.current()
	assert_true(v.begins_with("n1-") and v.length() == 13, "format n1-xxxxxxxxxx (%s)" % v)
	assert_eq(NetVersion.current(), v, "stable")
	var c: CardData = CardDB.card(&"mossback")
	var old: int = c.attack
	c.attack += 1
	assert_true(NetVersion.current() != v, "a stat change changes the version")
	c.attack = old
	assert_eq(NetVersion.current(), v, "back to the same version")
	var e: EffectData = null
	for card: CardData in CardDB.all_cards():
		if not card.effects.is_empty():
			e = card.effects[0]
			break
	var amount: int = e.amount
	e.amount += 1
	assert_true(NetVersion.current() != v, "an effect change changes the version")
	e.amount = amount
	assert_eq(NetVersion.current(), v, "back again")
	return true


func test_rules_hash_ignores_the_stamp_file() -> bool:
	var files: PackedStringArray = NetVersion.rules_files()
	assert_true(files.size() > 10, "core sources found")
	assert_true(not files.has("res://core/rules_stamp.gd"), "stamp file left out")
	assert_true(files.has("res://core/rules.gd"), "rules.gd included")
	return true
