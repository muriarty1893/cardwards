extends SceneTree
## Dev: prints the rules text of the given cards.
##   godot --headless --path . --script res://tools/diag/texts.gd -- id,id,...
func _initialize() -> void:
	for id: String in OS.get_cmdline_user_args()[0].split(","):
		var c: CardData = CardDB.card(StringName(id))
		var stats: String = " %d/%d" % [c.attack, c.health] if c.is_creature() else ""
		print("%s [%d%s]: %s" % [c.display_name, c.cost, stats, CardText.render(c)])
	quit()
