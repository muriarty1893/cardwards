class_name NoiseBank
extends RefCounted
## Seamless noise textures generated once and shared by the ground and lane shaders, so the
## GPU samples a texture instead of computing noise per pixel (big win on integrated GPUs).
## About 5 features across one texture repeat: shaders sample with uv = q * 0.2 to get one
## feature per unit of q.

const SIZE := 256

static var _fbm: Texture2D
static var _cell: Texture2D


## Smooth fractal noise in 0..1.
static func fbm() -> Texture2D:
	if _fbm == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		n.fractal_type = FastNoiseLite.FRACTAL_FBM
		n.fractal_octaves = 3
		n.frequency = 0.02
		n.seed = 11
		_fbm = ImageTexture.create_from_image(n.get_seamless_image(SIZE, SIZE))
	return _fbm


## Cellular "distance to the nearest border" in 0..1: small values are cell borders (cracks).
static func cells() -> Texture2D:
	if _cell == null:
		var n := FastNoiseLite.new()
		n.noise_type = FastNoiseLite.TYPE_CELLULAR
		n.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
		n.fractal_type = FastNoiseLite.FRACTAL_NONE
		n.frequency = 0.02
		n.seed = 23
		_cell = ImageTexture.create_from_image(n.get_seamless_image(SIZE, SIZE))
	return _cell
