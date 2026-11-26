"""Moss Ape Matriarch (Mushroom Forest, 6): a huge silverback of the deep forest, moss-furred
shoulders, stone-and-bark bracers, a crown of antler twigs with glowing blossoms."""
from forge import kits, props


def build(C):
    C.palette(fur="2e3a26", moss="5f9a2e", face="3a302c", eye="ffcf3a", dark="0e0c0a", stone="7a7f74",
              bark="5a3e28", bloom="ff7ac8", antler="d8c8a8")
    C.attack = "slam"
    kits.biped(C, "fur", hip=0.8, chest=1.36, neck=1.55, head_top=1.85, shoulder_x=0.5, hip_x=0.22,
               hand=(0.62, -0.25, 0.12), r_hip=0.32, r_waist=0.34, r_chest=0.55, r_neck=0.2, r_head=0.22,
               r_arm=0.16, r_hand=0.15, r_leg=0.15, r_foot=0.14, lean=0.32, elbow_back=0.05)
    h = C.anch["head"]
    # face: dark muzzle, heavy brow, glowing eyes
    C.ellipsoid("Muzzle", (0, h[1] - 0.17, h[2] - 0.08), (0.17, 0.12, 0.12), "face", "head")
    C.box("Brow", (0, h[1] - 0.17, h[2] + 0.07), (0.34, 0.12, 0.08), "fur", "head", rot=(15, 0, 0), bevel=0.5)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.08 * mx, h[1] - 0.22, h[2] + 0.02), (0.035, 0.015, 0.022), "eye", "head")
        C.ellipsoid(f"Nostril{mx}", (0.04 * mx, h[1] - 0.29, h[2] - 0.05), (0.02, 0.01, 0.015), "dark", "head")
        C.cone(f"Fang{mx}", (0.08 * mx, h[1] - 0.27, h[2] - 0.13), (0.085 * mx, h[1] - 0.29, h[2] - 0.22), 0.025,
               "antler", "head", segs=5)
    # antler-twig crown with blossoms
    for mx in (-1, 1):
        C.tube(f"Antler{mx}", [(0.1 * mx, h[1], h[2] + 0.16), (0.22 * mx, h[1] + 0.02, h[2] + 0.34),
                               (0.36 * mx, h[1] - 0.04, h[2] + 0.46)], [0.035, 0.025, 0.006], "antler", "head")
        C.tube(f"AntlerB{mx}", [(0.2 * mx, h[1] + 0.02, h[2] + 0.3), (0.2 * mx, h[1] + 0.1, h[2] + 0.48)],
               [0.02, 0.005], "antler", "head")
        C.ellipsoid(f"Bloom{mx}", (0.14 * mx, h[1] - 0.06, h[2] + 0.2), (0.06, 0.05, 0.04), "bloom", "head")
    # moss mantle over the shoulders and back
    c = C.anch["chest"]
    for k, (x, z, s) in enumerate([(0, 0.32, 0.3), (0.32, 0.22, 0.22), (-0.32, 0.22, 0.22), (0.18, 0.4, 0.18),
                                   (-0.18, 0.4, 0.18)]):
        C.ellipsoid(f"Mantle{k}", (x, c[1] + 0.12, c[2] + z), (s, s * 0.9, s * 0.55), "moss", "chest")
    for k in range(5):
        C.decal(f"BackMoss{k}", -0.2 + 0.1 * k, c[2] - 0.15 - 0.06 * (k % 2), (0.1, 0.08, 0.04), "moss", "chest",
                dir=(0, -1, 0))
    # stone bracers on the forearms, bark knuckle wraps
    for side in ("L", "R"):
        fa = C.bones[f"forearm.{side}"]
        mid = fa["head"].lerp(fa["tail"], 0.55)
        C.ellipsoid(f"Bracer{side}", tuple(mid), (0.19, 0.19, 0.17), "stone", f"forearm.{side}")
        C.ellipsoid(f"Knuckle{side}", tuple(fa["tail"]), (0.16, 0.15, 0.12), "bark", f"forearm.{side}")
    C.decal("Chest", 0, c[2] - 0.1, (0.3, 0.22, 0.05), "face", "chest")
