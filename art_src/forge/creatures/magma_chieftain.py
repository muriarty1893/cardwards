"""Magma Chieftain (Ember Flats, 6): a hulking basalt brute. Sculpted: a gorilla-like hunched mass of
cooled black rock, huge shoulders and knuckle-dragging arms, a small head sunk between the shoulders
under a horned skull crown, tusks, lava glowing through the cracks, obsidian pauldrons, a wrapped loincloth
and a molten stone maul."""
from mathutils import Vector as V
from forge import props, skulpt
from forge.sculpt import recolor, smoothstep, cracks, crease


def build(C):
    C.palette(rock="2b2422", lava="ff6a1a", glow="ffc23a", bone="e8dcc0", obs="15121a", wrap="7a3a22", metal="4a4048",
              eye="ffd03a")
    C.attack = "slam"
    cl, at = skulpt.biped(C, hip=0.82, chest=1.36, head=1.6, lean=0.18, shoulder_x=0.42, hip_x=0.18,
                          r_chest=(0.38, 0.28, 0.3), r_waist=(0.26, 0.2, 0.2), r_hips=(0.26, 0.2, 0.16),
                          r_head=(0.13, 0.14, 0.13), r_arm=(0.15, 0.13), r_hand=0.12, r_leg=(0.15, 0.12),
                          r_foot=(0.12, 0.15, 0.07), arm_len=0.85, hand_fwd=0.12, group="rock", jaw=True)
    h = at["head"]
    cl.mirror((0.22, 0.02, 1.52), (0.22, 0.18, 0.16), rot=(0, -20, 0), group="rock")        # trapezius mass
    cl.mirror((0.14, -0.3, 1.22), (0.14, 0.1, 0.12), group="rock")                          # pectorals
    for sx in (-1, 1):
        cl.add((sx * 0.5, -0.12, 1.0), (0.17, 0.17, 0.2), group="rock")                     # forearm bulk
        cl.add((0.05 * sx, h.y - 0.12, h.z + 0.04), (0.05, 0.03, 0.03), group="rock", neg=True)
    cl.add((0, h.y - 0.1, h.z + 0.07), (0.13, 0.06, 0.04), group="rock")                     # brow shelf
    cl.add((0, h.y - 0.08, h.z - 0.09), (0.12, 0.1, 0.07), group="rock")                     # jaw
    cl.add((0, -0.02, 0.84), (0.28, 0.22, 0.12), group="wrap")                                # loincloth
    cl.add((0, -0.22, 0.66), (0.14, 0.05, 0.18), group="wrap")
    body = cl.build({"rock": "rock", "wrap": "wrap"}, voxel=0.016, budget=11000, relax=2,
                    texture={"type": 'VORONOI', "scale": 0.06, "strength": 0.02})
    recolor(body, lambda p, n: 0.9 * cracks(p, 0.3, 0.05, seed=19) * (0.0 if 0.6 < p.z < 0.95 and abs(p.x) < 0.3 else 1.0),
            "lava")
    crease(body, "lava", 0.62, 0.86)
    recolor(body, lambda p, n: smoothstep(0.26, 0.0, (p - V((0, -0.28, 1.3))).length) * 0.6, "glow")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.05 * mx, h.y - 0.135, h.z + 0.04), (0.022, 0.012, 0.014), "eye", "head")
        C.cone(f"Tusk{mx}", (0.07 * mx, h.y - 0.13, h.z - 0.08), (0.11 * mx, h.y - 0.16, h.z + 0.04), 0.025, "bone",
               "jaw", segs=6)
        C.tube(f"Horn{mx}", [h + V((0.1 * mx, 0.0, 0.1)), h + V((0.24 * mx, 0.02, 0.18)), h + V((0.3 * mx, -0.04, 0.34))],
               [0.045, 0.035, 0.004], "bone", "head")
        sh = at["sh" + ("L" if mx < 0 else "R")]
        C.ellipsoid(f"Pauldron{mx}", tuple(sh + V((0.04 * mx, 0, 0.1))), (0.2, 0.2, 0.12), "obs", f"arm.{'L' if mx < 0 else 'R'}",
                    rot=(0, -25 * mx, 0))
        for k in range(2):
            C.cone(f"PSpike{mx}{k}", tuple(sh + V((0.08 * mx, -0.06 + 0.12 * k, 0.16))),
                   tuple(sh + V((0.2 * mx, -0.08 + 0.14 * k, 0.36))), 0.045, "obs", f"arm.{'L' if mx < 0 else 'R'}", segs=5)
    C.ellipsoid("SkullCrown", tuple(h + V((0, -0.02, 0.12))), (0.11, 0.11, 0.07), "bone", "head")
    hr = at["hdR"]
    C.tube("MaulHaft", [hr + V((0, 0.06, 0.12)), hr + V((0, -0.08, -0.25)), hr + V((0, -0.14, -0.5))], [0.035, 0.035, 0.035],
           "wrap", "forearm.R")
    C.box("MaulHead", tuple(hr + V((0, -0.16, -0.58))), (0.26, 0.2, 0.2), "rock", "forearm.R", bevel=0.25)
    C.box("MaulGlow", tuple(hr + V((0, -0.16, -0.58))), (0.27, 0.12, 0.12), "lava", "forearm.R", bevel=0.25)
