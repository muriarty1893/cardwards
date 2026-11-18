extends SceneTree
func _initialize() -> void:
	for id: StringName in [&"cinderpup", &"rimewing", &"taffy_snail", &"glimmer_morel", &"mossback", &"flarebeak", &"snowmite", &"volcano", &"snowstorm", &"spore_bloom", &"sugar_rain", &"bark_shield", &"candy_shell"]:
		print(id, ": ", CardText.render(CardDB.card(id)))
	print(CardText.tooltip(CardDB.card(&"cinderpup")))
	quit()
