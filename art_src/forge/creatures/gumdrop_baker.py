"""Gumdrop Baker (Candy Hills, 3): a burly sugar-crusted gumdrop golem in a chef's hat and apron,
swinging a huge rolling pin, a tray of fresh gumdrops strapped to its back."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(gum="2ad07a", sugar="c8ffe0", dark="0e2a1a", eye="fff2a0", hat="ffffff", apron="ff9ac0",
              wood="d89a5a", tray="b0b0b8", g1="ff4a6a", g2="ffd23a", g3="7a5aff")
    C.attack = "slam"
    kits.biped(C, "gum", hip=0.62, chest=1.05, neck=1.2, head_top=1.45, shoulder_x=0.4, hip_x=0.17,
               hand=(0.56, -0.1, 0.48), r_hip=0.36, r_waist=0.42, r_chest=0.44, r_neck=0.25, r_head=0.24,
               r_arm=0.11, r_hand=0.11, r_leg=0.13, r_foot=0.13, lean=0.05)
    import random
    rnd = random.Random(2)
    for k in range(26):
        x, z = rnd.uniform(-0.4, 0.4), rnd.uniform(0.5, 1.4)
        C.decal(f"Sugar{k}", x, z, (0.025, 0.025, 0.02), "sugar", "chest" if z > 0.9 else "hips",
                dir=(0, 1 if k % 2 else -1, 0))
    h = V(C.anch["head"])
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.09 * mx, -0.22, 0.02))), (0.04, 0.02, 0.03), "eye", "head")
        C.box(f"Brow{mx}", tuple(h + V((0.09 * mx, -0.22, 0.08))), (0.12, 0.04, 0.03), "dark", "head", rot=(0, 20 * mx, 0),
              bevel=0.4)
    C.box("Mouth", tuple(h + V((0, -0.23, -0.07))), (0.14, 0.02, 0.03), "dark", "head", bevel=0.4)
    # chef hat
    C.lathe("HatBand", [(0.2, 0.0), (0.21, 0.08)], "hat", "head", segs=20)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(h + V((0, 0, 0.14))))
    for k, (x, y, s) in enumerate([(0, 0, 0.2), (0.12, 0.05, 0.13), (-0.12, 0.05, 0.13), (0.0, 0.1, 0.14)]):
        C.ellipsoid(f"HatPuff{k}", tuple(h + V((x, y, 0.33))), (s, s, s * 0.8), "hat", "head")
    # apron
    C.box("Apron", (0, -0.4, 0.75), (0.5, 0.04, 0.6), "apron", "hips", rot=(-8, 0, 0), bevel=0.2, taper=(0.85, 1))
    C.box("Pocket", (0, -0.43, 0.65), (0.22, 0.03, 0.12), "hat", "hips", rot=(-8, 0, 0), bevel=0.3)
    # rolling pin
    hr = V(C.anch["hdR"])
    C.tube("Pin", [hr + V((0, 0, 0.12)), hr + V((0, 0, -0.25)), hr + V((0, 0, -0.7))], [0.07, 0.075, 0.07], "wood",
           "forearm.R")
    for z in (0.22, -0.8):
        C.tube(f"PinHandle{z}", [hr + V((0, 0, z - 0.1 if z > 0 else z + 0.1)), hr + V((0, 0, z))], [0.025, 0.025], "wood",
               "forearm.R")
    # tray of gumdrops on its back
    C.box("Tray", (0, 0.42, 1.1), (0.6, 0.04, 0.45), "tray", "chest", rot=(15, 0, 0), bevel=0.2)
    for k, (x, z, m) in enumerate([(-0.18, 1.2, "g1"), (0.0, 1.22, "g2"), (0.18, 1.2, "g3"), (-0.1, 1.02, "g2"),
                                   (0.1, 1.02, "g1")]):
        C.cone(f"Drop{k}", (x, 0.47, z - 0.04), (x, 0.47, z + 0.08), 0.07, m, "chest", segs=10, smooth=True)
