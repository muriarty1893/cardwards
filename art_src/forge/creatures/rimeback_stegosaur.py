"""Rimeback Stegosaur (Frost Peaks, 9): an armoured stegosaur with a double row of great ice-crystal plates
down its back, frost-rimed hide, a club-spiked thagomizer of icicles and a low, horned skull."""
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(hide="4a6a6a", hide2="8aaab0", belly="c8d8d0", ice="9ee8ff", ice2="e0faff", eye="ffd23a",
              dark="0e1418", horn="d8d0c0")
    C.attack = "ram"
    kits.quad(C, "hide", hip=(0.32, 0.92), chest=(-0.26, 0.82), neck=(-0.5, 0.65), head=(-0.82, 0.55),
              r_hip=0.42, r_chest=0.4, r_waist=0.44, r_neck=0.2, r_head=0.17, r_snout=0.12, r_leg=0.14, r_paw=0.16,
              knee=0.45, leg_x=0.3, tail=((0.66, 0.85), (0.9, 0.72), (1.08, 0.66)), r_tail=0.2, muscle=1.25,
              head_drop=0.04)
    at = C.at
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.1, -0.03, 0.03, mx), (0.03, 0.025, 0.02), "eye", "head")
        C.box(f"Brow{mx}", at("brow", 0.1, -0.03, 0.07, mx), (0.1, 0.06, 0.03), "hide2", "head", rot=(0, 25 * mx, 0),
              bevel=0.4)
        C.cone(f"Horn{mx}", at("cran", 0.1, 0.02, 0.08, mx), at("cran", 0.18, 0.12, 0.2, mx), 0.04, "horn", "head", segs=5)
    C.ellipsoid("Jaw", at("snout", 0, 0.02, -0.07), (0.1, 0.16, 0.04), "belly", "jaw")
    C.decal("Belly", 0, -1, (0.35, 0.55, 0.05), "belly", "chest", dir=(0, 0, 1), y=0.0, spin=90)
    # frost speckles
    import random
    rnd = random.Random(8)
    for k in range(12):
        x, y = rnd.uniform(-0.35, 0.35), rnd.uniform(-0.4, 0.5)
        C.decal(f"Rime{k}", x, 3, (0.06, 0.05, 0.02), "hide2", "chest" if y < 0.05 else "hips", dir=(0, 0, -1), y=y)
    # two rows of crystal plates, tallest over the hips
    pts = []
    for k in range(7):
        y = -0.5 + 0.17 * k
        loc, nor = C.surf(0.06, 3, dir=(0, 0, -1), y=y)
        if loc is None:
            continue
        hgt = 0.25 + 0.3 * (1 - abs(y - 0.2) / 0.8)
        for mx in (-1, 1):
            base = V((0.07 * mx, y + 0.02 * mx, loc.z - 0.03))
            C.membrane(f"Plate{k}{mx}", [tuple(base + V((0, -0.11, 0))), tuple(base + V((0.05 * mx, 0.0, hgt))),
                                         tuple(base + V((0, 0.11, 0)))], "ice" if k % 2 else "ice2",
                       "chest" if y < 0.05 else "hips", thick=0.05)
    # icicle thagomizer
    tip = V(C.anch["t2"])
    for mx in (-1, 1):
        for k in range(2):
            b = tip + V((0.06 * mx, -0.12 + 0.12 * k, 0.04))
            C.cone(f"Thag{mx}{k}", tuple(b), tuple(b + V((0.32 * mx, 0.1 + 0.05 * k, 0.22))), 0.05, "ice2", "tail3", segs=5)
