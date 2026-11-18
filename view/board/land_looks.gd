class_name LandLooks
extends RefCounted
## The 12 land looks (board look 2, spec 2). Builders place their pieces with SetPieces' kit inside ctx "box" (back
## corner), "other_box", "band" / "other_band" (side strips); ctx "scale" shrinks tall pieces on your side.


## Builds ctx's land/variant look; false if that look has no builder (SetPieces then uses a rock cluster).
static func build(ctx: Dictionary) -> bool:
	match Vector2i(int(ctx["land"]), int(ctx["variant"])):
		_:
			return false
