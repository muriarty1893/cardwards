"""Snowmite (Frost Peaks, 2): a bloated snow tick the size of a dog, a fluffy white back that hides it in
drifts, a hard blue head with icicle mandibles and six spindly frost-rimed legs."""
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(fluff="f4f8ff", fluff2="d8e4f0", head="2a5a8a", leg="1a3a5a", ice="cff4ff", eye="ff3a5a")
    C.attack = "bite"
    C.relax = 0.8
    kits.quad(C, "leg", hip=(0.16, 0.3), chest=(-0.12, 0.32), neck=(-0.26, 0.3), head=(-0.45, 0.28),
              r_hip=0.1, r_chest=0.1, r_waist=0.1, r_neck=0.08, r_head=0.12, r_snout=0.08, r_leg=0.03, r_paw=0.03,
              knee=0.3, leg_x=0.34, tail=((0.3, 0.3),), r_tail=0.04, head_m="head")
    C.ellipsoid("Back", (0, 0.05, 0.42), (0.36, 0.42, 0.28), "fluff", None)
    C.parts[-1] = (C.parts[-1][0], None, ["hips", "chest"])
    import random
    rnd = random.Random(2)
    for k in range(12):
        x, y = rnd.uniform(-0.25, 0.25), rnd.uniform(-0.25, 0.35)
        C.decal(f"Tuft{k}", x, 2, (0.09, 0.09, 0.05), "fluff2", "chest" if y < 0.05 else "hips", part="Back", dir=(0, 0, -1),
                y=y)
    at = C.at
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.07, -0.05, 0.03, mx), (0.025, 0.02, 0.02), "eye", "head")
        base = V(at("snout", 0.05, -0.04, -0.02, mx))
        C.tube(f"Mandible{mx}", [base, base + V((0.06 * mx, -0.1, -0.02)), base + V((0.0, -0.18, -0.04))],
               [0.03, 0.022, 0.004], "ice", "head")
        C.tube(f"MidLeg{mx}", [V((0.2 * mx, 0.0, 0.3)), V((0.36 * mx, -0.02, 0.32)), V((0.42 * mx, 0.02, 0.0))],
               [0.03, 0.025, 0.015], "leg", "chest")
