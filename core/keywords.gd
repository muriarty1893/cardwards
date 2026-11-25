class_name Keywords
extends RefCounted
## Names and one-line rules of the keywords and card mechanics (spec section 4).

## Printed order on cards.
const ORDER: Array[StringName] = [&"guard", &"bubble", &"dash", &"venom", &"leech", &"flurry", &"hidden", &"second_wind", &"sturdy", &"bask"]

const NAMES: Dictionary = {
	&"guard": "Guard", &"bubble": "Bubble", &"dash": "Dash", &"venom": "Venom",
	&"leech": "Leech", &"flurry": "Flurry", &"hidden": "Hidden", &"second_wind": "Second Wind",
	&"hush": "Hush", &"dream_up": "Dream Up", &"combo": "Combo", &"spell_power": "Spell Power",
	&"field": "Field", &"armour": "Armour", &"level_up": "Level up", &"sturdy": "Sturdy", &"bask": "Bask",
	&"last_breath": "Last Breath", &"curse": "Curse", &"dark_gift": "Dark Gift", &"echo": "Echo", &"follower": "Follower",
}

const RULES: Dictionary = {
	&"guard": "Enemies must attack a Guard before your other creatures or your hero.",
	&"bubble": "Blocks the next damage it would take, then pops.",
	&"dash": "Can attack enemy creatures on the turn it is played.",
	&"venom": "Destroys any creature it damages.",
	&"leech": "Damage it deals also heals your hero.",
	&"flurry": "Can attack twice each turn.",
	&"hidden": "Can't be attacked or targeted by enemies until it attacks or boops.",
	&"second_wind": "The first time it is destroyed, it comes back with 1 HP.",
	&"hush": "Removes a creature's keywords, abilities and stat changes, and unfreezes it.",
	&"dream_up": "Choose one of 3 random cards to add to your hand.",
	&"combo": "Only happens if you already played another card this turn.",
	&"spell_power": "Your spells deal that much extra damage.",
	&"field": "Stays in play for both players until another field replaces it.",
	&"armour": "Soaks damage to your hero before its HP does.",
	&"sturdy": "Takes 1 less damage from every hit.",
	&"bask": "At the end of your turn, if it didn't attack, it gets +1/+1.",
	&"last_breath": "Happens when this creature dies (not if it's Hushed).",
	&"curse": "A bad card made for the rival. Some go off when drawn.",
	&"dark_gift": "Choose one of 3 random creatures; the one you take gets a random bonus.",
	&"follower": "Shares its leader's land. It fights and can be hit on its own, and takes over the land if its leader falls.",
	&"echo": "While this is in play, your creatures' and buildings' on-play effects happen twice.",
	&"level_up": "A creature gains XP for each attack it survives (+1 more for a kill): Lv 2 at 2 XP, Lv 3 at 4 XP, +1/+1 each.",
}
