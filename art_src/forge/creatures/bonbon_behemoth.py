"""Bonbon Behemoth (Candy Hills, 6): a hulking chocolate rabbit brute, its hollow shell cracked open to
show cream filling, gold foil wrapped like armour plates, long ears notched from fights and fists studded
with bonbons."""
import random
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(choc="5a2a14", choc2="7a3a1a", cream="fff0d8", foil="ffcf3a", foil2="c81a3a", eye="ff3a7a", dark="1a0804",
              bonbon="3a1408", nut="c8904a")
    C.attack = "slam"
    kits.biped(C, "choc", hip=0.78, chest=1.28, neck=1.45, head_top=1.72, shoulder_x=0.46, hip_x=0.22,
               hand=(0.64, -0.2, 0.5), r_hip=0.34, r_waist=0.36, r_chest=0.46, r_neck=0.2, r_head=0.2,
               r_arm=0.13, r_hand=0.13, r_leg=0.15, r_foot=0.16, lean=0.2)
    h = V(C.anch["head"])
    rnd = random.Random(6)
    # cracked shell with cream filling
    for k, (x, z, s) in enumerate([(0.15, 1.2, 0.12), (-0.18, 1.0, 0.1), (0.05, 0.9, 0.08)]):
        C.decal(f"Crack{k}", x, z, (s, s * 0.7, 0.04), "cream", "chest", spin=rnd.uniform(0, 180))
    # gold foil armour
    c = V(C.anch["chest"])
    C.ellipsoid("FoilChest", tuple(c + V((0, -0.02, 0.05))), (0.42, 0.36, 0.24), "foil", "chest")
    C.ellipsoid("FoilBand", tuple(c + V((0, -0.04, -0.12))), (0.44, 0.38, 0.06), "foil2", "chest")
    props.pauldrons(C, "foil", spikes="foil2", size=0.2)
    # rabbit head: notched ears, angry eyes, buck teeth
    for mx in (-1, 1):
        C.tube(f"Ear{mx}", [h + V((0.08 * mx, 0.02, 0.14)), h + V((0.14 * mx, 0.06, 0.4)), h + V((0.18 * mx, 0.12, 0.66))],
               [0.06, 0.07, 0.03], "choc2", "head")
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.075 * mx, -0.18, 0.04))), (0.035, 0.015, 0.022), "eye", "head")
        C.box(f"Brow{mx}", tuple(h + V((0.075 * mx, -0.18, 0.08))), (0.08, 0.03, 0.02), "dark", "head", rot=(0, 25 * mx, 0),
              bevel=0.4)
    C.box("NotchL", tuple(h + V((-0.15, 0.08, 0.5))), (0.04, 0.06, 0.05), "cream", "head", bevel=0.3)
    C.ellipsoid("Muzzle", tuple(h + V((0, -0.16, -0.06))), (0.1, 0.07, 0.07), "choc2", "head")
    for mx in (-1, 1):
        C.box(f"Tooth{mx}", tuple(h + V((0.02 * mx, -0.22, -0.11))), (0.035, 0.02, 0.05), "cream", "head", bevel=0.2)
    # bonbon-studded fists
    for side in ("L", "R"):
        hd = V(C.anch["hd" + side])
        C.ellipsoid(f"Fist{side}", tuple(hd), (0.17, 0.17, 0.16), "choc2", f"forearm.{side}")
        for k in range(3):
            C.ellipsoid(f"Bonbon{side}{k}", tuple(hd + V((0.08 * (k - 1), -0.15, 0.03))), (0.045, 0.04, 0.045), "bonbon",
                        f"forearm.{side}")
            C.ellipsoid(f"Nut{side}{k}", tuple(hd + V((0.08 * (k - 1), -0.185, 0.05))), (0.015, 0.01, 0.015), "nut",
                        f"forearm.{side}")
    C.ellipsoid("Tail", (0, 0.32, 0.8), (0.1, 0.1, 0.1), "cream", "hips")
