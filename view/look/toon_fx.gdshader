shader_type spatial;
render_mode cull_disabled;
// Toon material with per-instance hit flash and dissolve, for creatures.

#define INSTANCE_FX
#include "res://view/look/toon_body.gdshaderinc"
