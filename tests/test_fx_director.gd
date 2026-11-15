extends TestCase
## Effect choice: which visual kind plays for a (source, event) pair.

func _ab(card: StringName) -> Dictionary:
	return {"kind": &"ability", "player": 0, "lane": 0, "card": card}

func test_choose_table() -> bool:
	var dmg := GameEvent.make(&"creature_damaged", {"player": 1, "lane": 0, "amount": 3})
	assert_eq(FxDirector.choose({}, dmg), &"plain", "no source")
	assert_eq(FxDirector.choose({"kind": &"attack", "player": 0, "lane": 0, "hit": 1}, dmg), &"attack_hit", "attack")
	assert_eq(FxDirector.choose(_ab(&"fireball"), dmg), &"fireball", "fireball")
	assert_eq(FxDirector.choose(_ab(&"ashmite"), dmg), &"damage", "ashmite boop")
	assert_eq(FxDirector.choose(_ab(&"sporeling"), GameEvent.make(&"creature_healed", {})), &"heal", "heal boop")
	assert_eq(FxDirector.choose(_ab(&"snowmite"), GameEvent.make(&"frozen", {})), &"freeze", "freeze boop")
	assert_eq(FxDirector.choose(_ab(&"smokestack"), GameEvent.make(&"hero_damaged", {})), &"smoke_puff", "building")
	assert_eq(FxDirector.choose(_ab(&"candy_mill"), GameEvent.make(&"magic_changed", {})), &"gem_pop", "candy mill")
	return true

func test_every_card_has_known_effect() -> bool:
	for id: StringName in VisualDB.ids():
		assert_true(VisualDB.effect(id) in FxDirector.KINDS, "effect for %s" % id)
	return true
