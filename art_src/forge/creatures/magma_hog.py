"""Magma Hog (Ember Flats, 4): a lava-forged war boar, a hide of cooled black rock with magma glowing in the
cracks, obsidian tusks, a bristling ridge of fire down its spine and small furious eyes."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(rock="2e2624", magma="ff5a14", hot="ffc23a", tusk="1a1418", eye="ffd03a", snout="4a3a38")
    C.attack = "ram"
    C.relax = 0.6
    kits.quad(C, "rock", hip=(0.3, 0.62), chest=(-0.22, 0.7), neck=(-0.4, 0.68), head=(-0.68, 0.58),
              r_hip=0.3, r_chest=0.36, r_waist=0.3, r_neck=0.24, r_head=0.22, r_snout=0.14, r_leg=0.08, r_paw=0.09,
              knee=0.3, leg_x=0.22, tail=((0.5, 0.65),), r_tail=0.04, muscle=1.3, head_drop=0.04, jaw=False)
    at = C.at
    C.ellipsoid("Snout", at("nose", 0, -0.04, 0.0), (0.1, 0.06, 0.08), "snout", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Nostril{mx}", at("nose", 0.04, -0.1, 0.0, mx), (0.02, 0.01, 0.025), "magma", "head")
        C.ellipsoid(f"Eye{mx}", at("brow", 0.1, -0.05, 0.05, mx), (0.025, 0.02, 0.018), "eye", "head")
        C.box(f"Brow{mx}", at("brow", 0.1, -0.05, 0.08, mx), (0.08, 0.05, 0.03), "rock", "head", rot=(0, 25 * mx, 0),
              bevel=0.4)
        base = V(at("snout", 0.1, -0.02, -0.06, mx))
        C.tube(f"Tusk{mx}", [base, base + V((0.06 * mx, -0.1, 0.06)), base + V((0.04 * mx, -0.14, 0.18))],
               [0.04, 0.03, 0.005], "tusk", "head")
        C.cone(f"Ear{mx}", at("cran", 0.14, 0.04, 0.12, mx), at("cran", 0.22, 0.1, 0.24, mx), 0.06, "rock", "head", segs=5)
    import random
    rnd = random.Random(7)
    for k in range(10):
        x, y = rnd.uniform(-0.3, 0.3), rnd.uniform(-0.4, 0.4)
        C.decal(f"Crack{k}", x, 3, (0.08, 0.018, 0.018), "magma", "chest" if y < 0.04 else "hips", dir=(0, 0, -1), y=y,
                spin=rnd.uniform(0, 180))
    for mx in (-1, 1):
        for k in range(3):
            C.decal(f"SideCrack{mx}{k}", 0, 0.65, (0.09, 0.018, 0.018), "magma", "chest" if k < 2 else "hips",
                    dir=(-mx, 0, 0), y=-0.25 + 0.25 * k, spin=70 + 25 * k)
    for k in range(5):
        y = -0.35 + 0.17 * k
        loc = C.surf(0, 3, dir=(0, 0, -1), y=y)[0]
        if loc is not None:
            props.flame(C, loc, 0.09, "chest" if y < 0.04 else "hips", "magma", "hot", n=3, lean=(0, 0.5, 0), name=f"Ridge{k}")
