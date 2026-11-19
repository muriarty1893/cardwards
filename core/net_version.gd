class_name NetVersion
extends RefCounted
## The version two games must share to play online: the card data plus the rules code.
## Bump PROTOCOL when the online messages change.

const PROTOCOL := "n1"
const STAMP_FILE := "res://core/rules_stamp.gd"


static func current() -> String:
	return "%s-%s" % [PROTOCOL, (cards_fingerprint() + RulesStamp.HASH).md5_text().substr(0, 10)]


## md5 over every exported field of every card (effects included), cards sorted by id.
static func cards_fingerprint() -> String:
	var cards: Array[CardData] = CardDB.all_cards()
	cards.sort_custom(func(a: CardData, b: CardData) -> bool: return String(a.id) < String(b.id))
	var dump: Array = []
	for c: CardData in cards:
		dump.append(_fields(c))
	return var_to_str(dump).md5_text()


static func _fields(v: Variant) -> Variant:
	if v is Resource:
		var out: Array = []
		for prop: Dictionary in (v as Resource).get_property_list():
			var usage: int = prop["usage"]
			if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and usage & PROPERTY_USAGE_STORAGE:
				out.append([prop["name"], _fields((v as Resource).get(prop["name"]))])
		return out
	if v is Array:
		var arr: Array = []
		for x: Variant in v:
			arr.append(_fields(x))
		return arr
	return v


## The rules sources the stamp covers (only readable from the project, not in exported games).
static func rules_files() -> PackedStringArray:
	var out := PackedStringArray()
	var names: PackedStringArray = DirAccess.get_files_at("res://core")
	names.sort()
	for n: String in names:
		var path: String = "res://core/" + n
		if n.ends_with(".gd") and path != STAMP_FILE:
			out.append(path)
	return out


static func rules_source_hash() -> String:
	var text: String = ""
	for path: String in rules_files():
		text += path + "\n" + FileAccess.get_file_as_string(path) + "\n"
	return text.md5_text()
