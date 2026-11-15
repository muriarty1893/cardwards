shader_type spatial;
render_mode cull_disabled;
// Toon material with alpha-tested cut-outs plus per-instance hit flash and dissolve, for creatures.

#define CUTOUT
#define INSTANCE_FX
#include "res://view/look/toon_body.gdshaderinc"
