"""Blazehorn (Ember Flats, 5): a charging fire rhino. Sculpted: a massive, front-heavy body with a deep
shoulder hump, thick pillar legs, slabs of scorched armour plate riding its back and flanks with embers
glowing in the seams, a long heavy head with a great horn glowing white-hot at the tip, a frill of flame
behind its head and hooves that smoulder."""
from mathutils import Vector as V
from forge import props, skulpt
from forge.sculpt import recolor, smoothstep, cracks, crease


def build(C):
    C.palette(hide="6a463e", plate="2a1a18", horn="2a1a18", hot="fff0a0", fire="ff6a1a", flame2="ffd03a", eye="ffcf3a",
              ember="ff5a14", pupil="1a0a04")
    C.attack = "ram"
    cl, at = skulpt.quad(C, hip=(0.42, 0.98), chest=(-0.3, 1.04), r_chest=(0.34, 0.36, 0.3), r_belly=(0.31, 0.36, 0.26),
                         r_hips=(0.29, 0.28, 0.26), leg_x=0.25, r_thigh=0.17, r_shin=0.15, r_paw=0.16, paw_len=1.0,
                         neck=((-0.52, 1.0),), r_neck=(0.22,), head=(-0.7, 0.9), r_head=(0.22, 0.26, 0.2),
                         snout=(-1.08, 0.72), r_snout=(0.15, 0.12), tail=((0.66, 0.94), (0.76, 0.74)),
                         r_tail=(0.05, 0.02), digi=False, hump=(0.24, 0.26, 0.16), group="hide")
    h, s = at["head"], at["snout"]
    # armour slabs: overlapping plates along the back and flanks
    for k in range(4):
        y = -0.36 + 0.24 * k
        cl.add((0, y, 1.36 - 0.06 * k), (0.3 - 0.02 * k, 0.15, 0.08), rot=(-12, 0, 0), group="plate")
        cl.mirror((0.29, y, 1.1 - 0.04 * k), (0.08, 0.14, 0.2), rot=(0, 25, 0), group="plate")
    cl.add((0, -0.62, 1.16), (0.24, 0.1, 0.17), rot=(-35, 0, 0), group="plate")                  # neck shield
    for sx in (-1, 1):
        cl.add((0.14 * sx, h.y - 0.08, h.z + 0.08), (0.07, 0.07, 0.05), group="plate")       # brow plates
        cl.add((0.15 * sx, h.y - 0.12, h.z + 0.03), (0.035, 0.03, 0.03), group="hide", neg=True)
        cl.chain([(0.12 * sx, h.y + 0.04, h.z + 0.12), (0.16 * sx, h.y + 0.08, h.z + 0.22)], [0.05, 0.015],
                 group="hide")                                                                   # ears
    cl.add(tuple(s + V((0, 0.02, -0.08))), (0.12, 0.1, 0.06), group="hide")                    # lip
    body = cl.build({"hide": "hide", "plate": "plate"}, voxel=0.017, budget=11000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.04, "strength": 0.012})
    recolor(body, lambda p, n: 0.9 * cracks(p, 0.3, 0.05, seed=13) * smoothstep(1.05, 1.25, p.z), "ember")
    crease(body, "ember", 0.62, 0.86, fn=lambda p, n: 1.0 if p.z > 1.0 else 0.0)
    recolor(body, lambda p, n: smoothstep(0.14, 0.03, p.z) * 0.8, "ember")
    skulpt.eyes(C, [(0.15, h.y - 0.13, h.z + 0.03)], 0.025, "eye", "pupil")
    # the great horn, white-hot at the tip, and a little one behind it
    b = s + V((0, 0.06, 0.1))
    C.cone("Horn", tuple(b), tuple(b + V((0, -0.2, 0.55))), 0.13, "horn", "head", segs=10, smooth=True)
    C.cone("HornTip", tuple(b + V((0, -0.15, 0.4))), tuple(b + V((0, -0.2, 0.55))), 0.045, "hot", "head", segs=10,
           smooth=True)
    b2 = s + V((0, 0.2, 0.14))
    C.cone("Horn2", tuple(b2), tuple(b2 + V((0, -0.04, 0.16))), 0.07, "horn", "head", segs=8, smooth=True)
    pts = [tuple(V((0.0, -0.56, 1.24)) + V((0.12 * k, 0.02 * abs(k), -0.04 * abs(k)))) for k in (-2, -1, 0, 1, 2)]
    for k, p in enumerate(pts):
        props.flame(C, p, 0.2, "neck", "fire", "flame2", n=3, lean=(0, 0.6, 0.4), name=f"Frill{k}")
