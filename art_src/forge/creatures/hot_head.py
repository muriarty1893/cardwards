"""Hot Head (Ember Flats, 1): a short-fused fire imp. Sculpted: a squat, barrel-chested little brawler of
charcoal with magma veins, long arms ending in clenched glowing fists, goat legs on stomping hooves, two
stubby horns, and a whole head that is a living flame snarling with glowing eyes."""
from mathutils import Vector as V
from forge import props, skulpt
from forge.sculpt import recolor, smoothstep, cracks, crease


def build(C):
    C.palette(body="2a2024", vein="ff5a1a", fire="ff6a1a", hot="ffd03a", core="fff4c0", eye="1a0a08", hoof="140c0c",
              horn="3a2a2a")
    C.attack = "swipe"
    cl, at = skulpt.biped(C, hip=0.5, chest=0.86, head=1.08, lean=0.08, shoulder_x=0.26, hip_x=0.12,
                          r_chest=(0.25, 0.2, 0.2), r_waist=(0.16, 0.13, 0.12), r_hips=(0.17, 0.13, 0.11),
                          r_head=(0.15, 0.15, 0.15), r_arm=(0.07, 0.06), r_hand=0.085, r_leg=(0.09, 0.05),
                          r_foot=(0.05, 0.07, 0.05), arm_len=0.5, group="body", digi=True)
    h = at["head"]
    cl.mirror((0.1, -0.16, 0.8), (0.1, 0.07, 0.09), group="body")                 # pecs
    cl.mirror((0.06, h.y - 0.12, h.z + 0.02), (0.03, 0.03, 0.03), group="core", neg=True)
    cl.add((0, h.y - 0.13, h.z - 0.07), (0.07, 0.03, 0.03), group="core", neg=True)   # snarl
    body = cl.build({"body": "body", "core": "hot"}, voxel=0.01, budget=9000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.03, "strength": 0.01})
    recolor(body, lambda p, n: 0.9 * cracks(p, 0.3, 0.05, seed=23) * (1.0 if p.z < 0.98 else 0.0), "vein")
    crease(body, "vein", 0.62, 0.86, fn=lambda p, n: 1.0 if p.z < 0.98 else 0.0)
    recolor(body, lambda p, n: smoothstep(0.95, 1.05, p.z), "hot")
    recolor(body, lambda p, n: smoothstep(1.06, 1.2, p.z) * 0.8, "core")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.06 * mx, h.y - 0.13, h.z + 0.02), (0.028, 0.012, 0.02), "core", "head")
        C.cone(f"Horn{mx}", (0.1 * mx, h.y, h.z + 0.08), (0.17 * mx, h.y + 0.04, h.z + 0.2), 0.04, "horn", "head", segs=6)
        hd = at["hd" + ("L" if mx < 0 else "R")]
        C.ellipsoid(f"Fist{mx}", tuple(hd + V((0, -0.01, -0.05))), (0.09, 0.09, 0.09), "fire", f"forearm.{'L' if mx < 0 else 'R'}")
        ft = at["ft" + ("L" if mx < 0 else "R")]
        C.ellipsoid(f"Hoof{mx}", tuple(ft + V((0, -0.02, -0.02))), (0.06, 0.07, 0.04), "hoof", f"shin.{'L' if mx < 0 else 'R'}")
    props.flame(C, tuple(h + V((0, 0.02, 0.05))), 0.34, "head", "fire", "hot", n=6, lean=(0, 0.4, 0), m_core="core")
