"""Inferno Drake (Ember Flats, 7): a black-scaled wyvern that stands on two legs and its wing-claws,
jagged horns, a throat glowing with the fire it is about to breathe and a barbed tail."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(scale="1e1618", scale2="3a2a2a", belly="ff7a1a", glow="ffd03a", horn="c8b8a0", wing="5a1a10",
              wingbone="140e0e", eye="ffcf3a", fire="ff5a14", tooth="f0e6d0")
    C.attack = "dive"
    kits.quad(C, "scale", hip=(0.3, 0.72), chest=(-0.18, 0.95), neck=(-0.38, 1.42), head=(-0.78, 1.5),
              r_hip=0.3, r_chest=0.34, r_waist=0.27, r_neck=0.14, r_head=0.18, r_snout=0.11, r_leg=0.11, r_paw=0.12,
              knee=0.36, leg_x=0.24, tail=((0.62, 0.62), (0.92, 0.5), (1.1, 0.55)), r_tail=0.13, muscle=1.35,
              front=False)
    C.plan, C.hover = "flyer", 0.4
    at = C.at
    n0, n1 = V(C.anch["chest"]), V(C.anch["nb"])
    for k in range(4):
        p = n0.lerp(n1, 0.15 + 0.22 * k)
        C.ellipsoid(f"Throat{k}", tuple(p + V((0, -0.11, -0.02))), (0.11, 0.06, 0.1), "belly", "neck" if k > 1 else "chest")
    C.ellipsoid("ThroatGlow", tuple(n0.lerp(n1, 0.6) + V((0, -0.15, 0))), (0.06, 0.03, 0.08), "glow", "neck")
    C.ellipsoid("Jaw", at("snout", 0, 0.02, -0.08), (0.1, 0.18, 0.04), "scale2", "jaw")
    C.teeth("Tooth", [at("snout", x, -0.1 + abs(x), -0.06) for x in (-0.06, -0.03, 0.03, 0.06)], (0, 0, -1), 0.05,
            "tooth", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.1, -0.05, 0.03, mx), (0.035, 0.035, 0.02), "eye", "head", rot=(0, 0, 30 * mx))
        C.box(f"Brow{mx}", at("brow", 0.1, -0.05, 0.07, mx), (0.1, 0.07, 0.03), "scale2", "head", rot=(0, 25 * mx, 0),
              bevel=0.4)
        for k, (dy, dz, ln) in enumerate([(0.0, 0.1, 0.36), (0.06, 0.02, 0.26), (0.1, -0.06, 0.18)]):
            b = V(at("cran", 0.1 + 0.03 * k, dy, dz, mx))
            C.tube(f"Horn{mx}{k}", [b, b + V((0.08 * mx, ln * 0.6, ln * 0.4)), b + V((0.05 * mx, ln, ln * 0.55))],
                   [0.04 - 0.008 * k, 0.025, 0.004], "horn", "head")
    # wings that double as front legs (wing-claws down at the ground)
    kits.wings(C, "wingbone", "wing", shoulder=(0.2, -0.12, 1.05), span=0.95, up=0.7, sweep=0.35, r=0.06, droop=0.85,
               fingers=4)
    for side, mx in (("L", -1), ("R", 1)):
        el = V(C.bones[f"wing2.{side}"]["head"])
        C.cone(f"WingClaw{side}", tuple(el), tuple(el + V((0.03 * mx, -0.1, 0.1))), 0.035, "horn", f"wing2.{side}", segs=5)
    # barbed tail
    tip = V(C.anch["t2"])
    for mx in (-1, 1):
        C.cone(f"Barb{mx}", tuple(tip), tuple(tip + V((0.18 * mx, 0.12, 0.05))), 0.05, "horn", "tail3", segs=4)
    C.cone("BarbTip", tuple(tip), tuple(tip + V((0, 0.24, 0.05))), 0.05, "horn", "tail3", segs=4)
    for k in range(5):
        y = -0.15 + 0.13 * k
        loc = C.surf(0, 3, dir=(0, 0, -1), y=y)[0]
        if loc is not None:
            C.cone(f"Ridge{k}", tuple(loc), tuple(loc + V((0, 0.07, 0.14))), 0.04, "horn", "chest" if y < 0.05 else "hips",
                   segs=4)
