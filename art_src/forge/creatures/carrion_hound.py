"""Carrion Hound (Mushroom Forest, 3): a gaunt grave-hound with a bare skull head, ribs showing,
bone spines, a ragged moss mane and sickly glowing eyes."""
from forge import kits


def build(C):
    C.palette(hide="2f3a2d", bone="e3d7b8", eye="c6ff3a", dark="12150f", moss="5f8f2e", claw="2a2520")
    C.attack = "bite"
    kits.quad(C, "hide", hip=(0.34, 0.72), chest=(-0.28, 0.80), neck=(-0.56, 1.0), head=(-0.98, 0.9),
              r_hip=0.23, r_chest=0.34, r_waist=0.17, r_neck=0.14, r_head=0.17, r_snout=0.09, r_leg=0.085,
              knee=0.36, leg_x=0.22, r_paw=0.08, tail=((0.62, 0.82), (0.86, 0.94), (1.04, 1.12)), r_tail=0.06,
              head_drop=0.04, muscle=1.15, head_m="bone")
    at = C.at
    for mx in (-1, 1):
        C.ellipsoid(f"Socket{mx}", at("brow", 0.075, -0.06, 0.03, mx), (0.055, 0.035, 0.038), "dark", "head",
                    rot=(0, 0, -20 * mx))
        C.ellipsoid(f"Glow{mx}", at("brow", 0.082, -0.08, 0.03, mx), (0.032, 0.02, 0.02), "eye", "head",
                    rot=(0, 0, -20 * mx))
        C.box(f"Brow{mx}", at("brow", 0.07, -0.07, 0.075, mx), (0.1, 0.06, 0.03), "bone", "head",
              rot=(0, 25 * mx, -20 * mx), bevel=0.5)
    C.ellipsoid("NoseHole", at("nose", 0, -0.06, 0.01), (0.035, 0.02, 0.022), "dark", "head")
    j = C.at("snout", 0, 0.02, -0.08)
    C.ellipsoid("Jaw", j, (0.07, 0.17, 0.035), "dark", "jaw", rot=(-8, 0, 0))
    C.teeth("ToothU", [at("snout", x, -0.1 + abs(x) * 1.2, -0.05) for x in (-0.05, -0.02, 0.02, 0.05)], (0, 0, -1),
            0.06, "bone", "head")
    C.teeth("ToothL", [at("snout", x, -0.06 + abs(x), -0.07) for x in (-0.04, 0.04)], (0, 0, 1), 0.05, "bone", "jaw")
    C.mirror_horn("Ear", at("cran", 0.09, 0.0, 0.1), at("cran", 0.17, 0.2, 0.28), 0.055, "hide", "head",
                  bend=(0.02, 0.0, 0.03))
    # exposed rib arcs on the flanks
    for i in range(4):
        y = -0.30 + i * 0.12
        top = C.anch["back"][2] + 0.04 - i * 0.02
        for sx in (-1, 1):
            C.tube(f"Rib{i}{sx}", [(0.04 * sx, y, top), (0.3 * sx, y + 0.02, top - 0.2), (0.22 * sx, y + 0.03, top - 0.48)],
                   [0.026, 0.028, 0.017], "bone", "chest" if i < 2 else "hips")
    # bone spines down the back
    zb = C.anch["back"][2]
    pts = [(0, -0.42 + i * 0.15, zb + 0.06 - 0.05 * abs(i - 1.5)) for i in range(6)]
    C.spikes("Spine", pts, lambda i, p: (0, 0.45, 1), [(0.05, 0.26 - 0.025 * i) for i in range(6)], "bone",
             bone=lambda i, p: "chest" if i < 3 else "hips")
    # ragged moss mane on the neck, swept back
    n = C.anch["neck"]
    for i, (x, dy, dz) in enumerate([(0, -0.05, 0.14), (0.1, 0.02, 0.1), (-0.1, 0.02, 0.1), (0.15, 0.1, 0.02),
                                     (-0.15, 0.1, 0.02), (0, 0.08, 0.16)]):
        b = (x, n[1] + dy, n[2] + dz)
        C.cone(f"Mane{i}", b, (x * 1.7, b[1] + 0.26, b[2] + 0.05), 0.07, "moss", "neck" if i < 3 else "chest", segs=5)
