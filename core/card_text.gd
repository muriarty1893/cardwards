class_name CardText
extends RefCounted
## Rules text generated from a card's keywords and effects (spec 5.2). The only source of card
## text, so the words on a card always match what it does.

const _PREFIX: Dictionary = {
	&"on_boop": "Boop: ", &"on_destroyed": "When destroyed: ",
	&"start_of_turn": "Start of your turn: ", &"end_of_turn": "End of your turn: ",
	&"after_damage": "After this damages a creature, ", &"on_hurt": "After this takes damage, ",
	&"on_level_up": "Level up: ", &"field_start": "Start of each turn: ", &"field_end": "End of each turn: ",
}
## How each `who` reads as the object of a sentence.
const _WHO: Dictionary = {
	&"chosen_creature": "a creature", &"chosen_own_creature": "one of your creatures",
	&"opposing": "the opposing creature", &"enemy_hero": "the enemy hero", &"own_hero": "your hero",
	&"all_enemy_creatures": "all enemy creatures", &"all_own_creatures": "all your creatures",
	&"self": "this creature", &"lane_creature": "the creature in this lane",
	&"damaged_creature": "it", &"same_target": "it",
	&"chosen_enemy_creature": "an enemy creature", &"chosen_damaged_enemy": "a damaged enemy creature",
	&"chosen_undamaged_creature": "an undamaged creature", &"chosen_frozen_enemy": "a frozen enemy creature",
	&"other_enemies": "every other enemy",
}
const _LANE_AURAS: Array[StringName] = [&"lane_atk", &"lane_hp", &"lane_keyword"]
const _KIND_WORDS: Array[String] = ["creature", "building", "spell"]


static func render(c: CardData) -> String:
	return _render(c, false)


## Same text with mechanic names in [b]bold[/b] for a RichTextLabel.
static func render_bbcode(c: CardData) -> String:
	return _render(c, true)


## One "Name: rule" line per mechanic the card uses; empty if none.
static func tooltip(c: CardData) -> String:
	var used: Array[StringName] = []
	for k: StringName in Keywords.ORDER:
		if k in c.keywords:
			used.append(k)
	if c.spell_power > 0:
		used.append(&"spell_power")
	for e: EffectData in c.effects:
		var k: StringName = &""
		if e.op == &"hush" or e.op == &"dream_up":
			k = e.op
		elif e.op == &"lane_keyword" or e.op == &"give_keyword":
			k = e.keyword
		if k != &"" and not k in used:
			used.append(k)
		if e.combo and not &"combo" in used:
			used.append(&"combo")
		if e.op == &"armour" and not &"armour" in used:
			used.append(&"armour")
		if e.when == &"on_level_up" and not &"level_up" in used:
			used.append(&"level_up")
	if c.field:
		used.push_front(&"field")
	var lines: Array[String] = []
	for k: StringName in used:
		lines.append("%s: %s" % [Keywords.NAMES[k], Keywords.RULES[k]])
	if c.tribe != &"":
		lines.append("%s: %s" % [Tribes.NAMES[c.tribe], Tribes.rules_text(c.tribe)])
	return "\n".join(lines)


static func _render(c: CardData, bold: bool) -> String:
	var parts: Array[String] = []
	var partners: Array[CardData] = []
	if c.kind == CardData.Kind.CREATURE:
		partners = CardDB.merge_partners(c.id)
	if partners.size() >= 2:
		parts.append("%s of %s + %s." % [_b("Merged form", bold), partners[0].display_name, partners[1].display_name])
	if c.field:
		parts.append(_b("Field", bold) + ".")
	for k: StringName in Keywords.ORDER:
		if k in c.keywords:
			parts.append(_b(Keywords.NAMES[k], bold) + ".")
	if c.spell_power > 0:
		parts.append("%s +%d." % [_b("Spell Power", bold), c.spell_power])
	var effs: Array[EffectData] = c.effects
	var run_key: String = ""
	var i: int = 0
	while i < effs.size():
		var e: EffectData = effs[i]
		if e.when == &"aura" and e.who == &"lane_creature" and e.op in _LANE_AURAS:
			var bits: Array[String] = []
			while i < effs.size() and effs[i].when == &"aura" and effs[i].who == &"lane_creature" and effs[i].op in _LANE_AURAS:
				bits.append(_aura_part(effs[i], bold))
				i += 1
			parts.append("The creature in this lane has %s." % " and ".join(bits))
			run_key = ""
			continue
		var key: String = "%s|%s|%s%d" % [e.when, e.combo, e.tribe, e.need]
		var prefix: String = "" if key == run_key else _prefix(c, e, bold)
		run_key = key
		# "Freeze X. If it was already frozen, deal N damage to it instead." (Icicle)
		if e.cond == &"target_frozen" and i + 1 < effs.size() and effs[i + 1].who == &"same_target" and effs[i + 1].cond == &"target_not_frozen":
			var other: EffectData = effs[i + 1]
			parts.append(prefix + _phrase(_as_who(other, e.who), bold) + ".")
			parts.append("If it was already frozen, %s instead." % _phrase(_as_who(e, &"same_target"), bold))
			i += 2
			continue
		var sentence: String = _phrase(e, bold)
		# A prefix ending in a comma ("After this takes damage, ") continues the sentence.
		if prefix.ends_with(", ") and not sentence.begins_with("["):
			sentence = sentence.substr(0, 1).to_lower() + sentence.substr(1)
		i += 1
		while i < effs.size() and effs[i].who == &"same_target" and effs[i].combo == e.combo:
			sentence += " and " + _phrase(effs[i], bold)
			i += 1
		parts.append(prefix + sentence + ".")
	if c.merge_with != &"":
		var other: CardData = CardDB.card(c.merge_with) if CardDB.has_card(c.merge_with) else null
		parts.append("%s %s." % [_b("Merges with", bold), other.display_name if other else String(c.merge_with)])
	return " ".join(parts)


## A copy of `e` aimed at `who` (to reword a step's target).
static func _as_who(e: EffectData, who: StringName) -> EffectData:
	var c: EffectData = e.duplicate()
	c.who = who
	return c


static func _b(word: String, bold: bool) -> String:
	return "[b]%s[/b]" % word if bold else word


static func _prefix(c: CardData, e: EffectData, bold: bool) -> String:
	var base: String = ""
	if e.when == &"on_play":
		base = "" if c.kind == CardData.Kind.SPELL else ("When merged: " if not c.collectible and c.kind == CardData.Kind.CREATURE and not CardDB.merge_partners(c.id).is_empty() else "On play: ")
	else:
		base = _PREFIX.get(e.when, "")
	if e.need > 0:
		var other: String = "another %s" % Tribes.NAMES[e.tribe] if e.need == 1 else "%d other %s" % [e.need, Tribes.PLURALS[e.tribe]]
		var cond: String = "if you control %s" % other
		base = cond.capitalize().left(1) + cond.substr(1) + ": " if base == "" else "%s, %s: " % [base.trim_suffix(": "), cond]
	if not e.combo:
		return base
	var combo: String = _b("Combo", bold)
	return "%s: " % combo if base == "" else "%s, %s: " % [base.trim_suffix(": "), combo]


static func _aura_part(e: EffectData, bold: bool) -> String:
	match e.op:
		&"lane_atk":
			return "+%d ATK" % e.amount
		&"lane_hp":
			return "+%d HP" % e.amount
	return _b(Keywords.NAMES.get(e.keyword, String(e.keyword)), bold)


static func _phrase(e: EffectData, bold: bool) -> String:
	var x: String = _WHO.get(e.who, String(e.who))
	if e.who == &"own_on_land":
		x = "that player's creatures on %s" % CardData.LAND_NAMES[e.filter_land]
	var s: String = ""
	match e.op:
		&"damage":
			s = "Deal %d %sdamage to %s" % [e.amount, "more " if e.combo and e.who == &"same_target" else "", x]
		&"heal":
			s = "Heal %s %d" % [x, e.amount]
		&"draw":
			s = "Draw a card" if e.amount == 1 else "Draw %d cards" % e.amount
		&"gain_magic":
			s = "Gain %d magic" % e.amount
		&"freeze":
			s = "Freeze %s" % x
		&"hush":
			s = "%s %s" % [_b("Hush", bold), x]
		&"return_building":
			s = "Return the opposing building to its owner's hand"
		&"move":
			s = "Move this creature to one of your empty lanes"
		&"swap":
			s = "Swap two of your creatures between lanes"
		&"return_from_discard":
			s = "Return a creature from your discard pile to your hand"
		&"dream_up":
			var land: String = CardData.LAND_NAMES[e.filter_land] + " " if e.filter_land >= 0 else ""
			var kind: String = _KIND_WORDS[e.filter_kind] if e.filter_kind >= 0 else "card"
			s = "%s a %s%s" % [_b("Dream Up", bold), land, kind]
		&"lane_damage_taken":
			s = "The creature in this lane takes %d less damage from attacks and hit-back (minimum 1)" % e.amount
		&"opposing_atk":
			s = "The opposing creature has −%d ATK (minimum 0)" % e.amount
		&"lane_atk", &"lane_hp", &"lane_keyword":
			s = "The creature in this lane has %s" % _aura_part(e, bold)
		&"buff":
			s = "Give %s +%d/+%d" % [x, e.amount, e.amount2]
		&"give_keyword":
			s = "Give %s %s" % [x, _b(Keywords.NAMES.get(e.keyword, String(e.keyword)), bold)]
		&"destroy":
			s = "Destroy %s" % x
		&"armour":
			s = "Gain %d %s" % [e.amount, _b("armour", bold)]
		&"temp_atk":
			s = "Give %s +%d ATK this turn" % [x, e.amount]
		&"doom":
			s = "Destroy %s at the end of your turn" % x
		&"grow_magic":
			s = "Gain %d max magic" % e.amount
		&"bounce":
			s = "Return %s to its owner's hand" % x
		&"spell_discount":
			s = "Your next spell this turn costs %d less" % e.amount
		&"transform":
			var into: CardData = CardDB.card(e.card_id) if CardDB.has_card(e.card_id) else null
			s = "Turn %s into a %d/%d %s with no abilities" % [x, into.attack if into else 1, into.health if into else 1, into.display_name if into else String(e.card_id).capitalize()]
		&"sprout_meadow":
			s = "That player's first Meadow lane grows into Mushroom Forest"
		&"land_draw":
			s = "If that player has a creature on %s, they draw a card" % CardData.LAND_NAMES[e.filter_land]
		&"on_land_atk":
			s = "Creatures on %s have %+d ATK" % [CardData.LAND_NAMES[e.filter_land], e.amount]
		&"off_land_atk":
			s = "Creatures not on %s have %s ATK" % [CardData.LAND_NAMES[e.filter_land], ("−%d" % -e.amount) if e.amount < 0 else "+%d" % e.amount]
		&"on_land_hp":
			s = "Creatures on %s have %+d HP" % [CardData.LAND_NAMES[e.filter_land], e.amount]
		&"no_quirk":
			s = "%s give no home bonus" % CardData.LAND_NAMES[e.filter_land]
		_:
			s = String(e.op)
	# "it" sentences continue an earlier clause, so they start lower-case.
	if x == "it" and not s.begins_with("["):
		s = s.substr(0, 1).to_lower() + s.substr(1)
	return s
