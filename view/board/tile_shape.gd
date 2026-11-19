class_name TileShape
extends RefCounted
## One half-lane tile's outline in tile-local space (x across, z along; the tile centre is the origin): its left and
## right edges follow the BoardLayout's border curves, its ends are at ±Island.LENGTH / 2.

var layout: BoardLayout
var lane: int = 0
## World position of the tile centre.
var tile_x: float = 0.0
var tile_z: float = 0.0
## The board half the tile lies in (0 yours, 1 the rival's): its borders are that half's.
var half: int = 0


static func of(layout_: BoardLayout, lane_: int, tile_z_: float) -> TileShape:
	var t := TileShape.new()
	t.layout = layout_
	t.lane = lane_
	t.half = BoardLayout.half_of(tile_z_)
	t.tile_x = layout_.base_centre(lane_, t.half)
	t.tile_z = tile_z_
	return t


## A straight tile of today's full lane width (2.7), for code and tests without a layout.
static func straight(lane_: int = 1, tile_z_: float = 2.85) -> TileShape:
	return of(BoardLayout.straight(), lane_, tile_z_)


func left(z: float) -> float:
	return layout.left_x(lane, tile_z + z) - tile_x


func right(z: float) -> float:
	return layout.right_x(lane, tile_z + z) - tile_x


func centre(z: float) -> float:
	return (left(z) + right(z)) / 2.0


func half_width(z: float) -> float:
	return (right(z) - left(z)) / 2.0


func contains(x: float, z: float) -> bool:
	return absf(z) <= Island.LENGTH / 2.0 and x >= left(z) and x <= right(z)


## Smallest |x| that covers the tile everywhere (for the mesh size).
func max_half_extent() -> float:
	var out: float = 0.0
	for k: int in 33:
		var z: float = lerpf(-Island.LENGTH / 2.0, Island.LENGTH / 2.0, k / 32.0)
		out = maxf(out, maxf(absf(left(z)), absf(right(z))))
	return out


## The tile's left/right edge curves as shader uniforms (world x; outer edges are flat curves at ±HALF_W).
func left_curve() -> Array[Vector4]:
	if lane == 0:
		return [Vector4(-BoardLayout.HALF_W, 0, 0, 0), Vector4.ZERO]
	return [layout.curve_params(lane - 1, half), layout.curve_params2(lane - 1, half)]


func right_curve() -> Array[Vector4]:
	if lane == 3:
		return [Vector4(BoardLayout.HALF_W, 0, 0, 0), Vector4.ZERO]
	return [layout.curve_params(lane, half), layout.curve_params2(lane, half)]
