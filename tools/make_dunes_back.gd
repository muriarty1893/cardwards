extends SceneTree
## Makes the Sunny Dunes card back from the user's Frostbound back: its blues turn sand-gold and its
## icy whites warm up; the gold frame and medallion rim stay as they are.
##   godot --headless --path . --script res://tools/make_dunes_back.gd


func _initialize() -> void:
	var img: Image = Image.load_from_file(ProjectSettings.globalize_path("res://assets/card_backs/frost.png"))
	img.convert(Image.FORMAT_RGBA8)
	for y: int in img.get_height():
		for x: int in img.get_width():
			var c: Color = img.get_pixel(x, y)
			if c.s > 0.18 and c.h > 0.45 and c.h < 0.78:
				# Blue → warm amber/sand, deeper blues → deeper orange.
				var t: float = clampf((c.h - 0.5) / 0.2, 0.0, 1.0)
				c = Color.from_hsv(lerpf(0.11, 0.07, t), clampf(c.s * 0.95, 0.0, 1.0), clampf(c.v * 1.05 + 0.04, 0.0, 1.0), c.a)
			elif c.s <= 0.18 and c.v > 0.8 and c.b > c.r:
				# Icy whites → warm cream.
				c = Color(minf(c.r * 1.02 + 0.02, 1.0), c.g * 0.98, c.b * 0.86, c.a)
			img.set_pixel(x, y, c)
	img.save_png(ProjectSettings.globalize_path("res://assets/card_backs/dunes.png"))
	print("saved dunes.png")
	quit()
