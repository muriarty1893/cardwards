shader_type spatial;
render_mode cull_disabled;
// Toon material with alpha-tested cut-outs (leaves, flowers, clover).

#define CUTOUT
#include "res://view/look/toon_body.gdshaderinc"
