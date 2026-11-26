"""Snowman (Frost Peaks, 1): a snowman that came to life angry, three lumpy snowballs, coal eyes glowing
ice-blue, a jagged grin of icicles, twig arms ending in icicle claws and a dented bucket worn like a helm."""
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(snow="f4f8ff", snow2="d8e4f0", coal="10141a", glow="5ad8ff", ice="cff4ff", twig="4a3424", bucket="5a6a7a",
              rust="8a5a3a", scarf="c81a2a")
    C.attack = "swipe"
    C.relax = 0.0
    C.plan = "biped"
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.3), (0, 0, 0.6), "root")
    C.bone("chest", (0, 0, 0.6), (0, 0, 0.85), "hips")
    C.bone("head", (0, 0, 0.85), (0, 0, 1.15), "chest")
    C.spine, C.head = ["hips", "chest"], "head"
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"arm.{side}", (0.2 * sx, 0, 0.72), (0.4 * sx, -0.05, 0.52), "chest")
        C.bone(f"forearm.{side}", (0.4 * sx, -0.05, 0.52), (0.52 * sx, -0.12, 0.38), f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))
    C.ellipsoid("Base", (0, 0, 0.28), (0.36, 0.34, 0.3), "snow", "hips")
    C.ellipsoid("Mid", (0, 0, 0.68), (0.26, 0.25, 0.23), "snow", "chest")
    C.ellipsoid("Head", (0, -0.02, 0.98), (0.19, 0.18, 0.18), "snow", "head")
    for k, (x, z) in enumerate([(0.2, 0.2), (-0.25, 0.35), (0.12, 0.6), (-0.1, 0.75)]):
        C.ellipsoid(f"Lump{k}", (x, -0.12, z), (0.09, 0.08, 0.07), "snow2", "hips" if z < 0.5 else "chest")
    C.lathe("Scarf", [(0.17, -0.03), (0.2, 0.0), (0.18, 0.04)], "scarf", "chest", segs=16)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, 0, 0.85)))
    C.box("ScarfEnd", (0.1, -0.15, 0.72), (0.06, 0.03, 0.2), "scarf", "chest", rot=(10, 0, 15), bevel=0.3)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.07 * mx, -0.17, 1.03), (0.035, 0.02, 0.03), "coal", "head")
        C.ellipsoid(f"Glow{mx}", (0.07 * mx, -0.185, 1.03), (0.018, 0.01, 0.015), "glow", "head")
        C.box(f"Brow{mx}", (0.07 * mx, -0.17, 1.075), (0.07, 0.02, 0.02), "coal", "head", rot=(0, 25 * mx, 0), bevel=0.3)
    C.cone("Nose", (0, -0.17, 0.98), (0, -0.3, 0.97), 0.025, "rust", "head", segs=6, smooth=True)
    for k in range(5):
        x = -0.08 + 0.04 * k
        C.cone(f"Icicle{k}", (x, -0.16, 0.92), (x, -0.17, 0.87 - 0.02 * (k % 2)), 0.015, "ice", "head", segs=4)
    for k in range(3):
        C.ellipsoid(f"Button{k}", (0, -0.25 + 0.02 * abs(k - 1), 0.55 + 0.12 * k), (0.03, 0.015, 0.03), "coal", "chest")
    # dented bucket helm
    C.lathe("Bucket", [(0.15, 0.0), (0.13, 0.18), (0.001, 0.19)], "bucket", "head", segs=14)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0.02, 0.0, 1.1)) @
                                  __import__("mathutils").Matrix.Rotation(-0.3, 4, 'Y'))
    # twig arms with icicle claws
    for side, mx in (("L", -1), ("R", 1)):
        a, f = C.bones[f"arm.{side}"], C.bones[f"forearm.{side}"]
        C.tube(f"Twig{side}", [a["head"], a["tail"], f["tail"]], [0.03, 0.025, 0.02], "twig", None,
               allowed=[f"arm.{side}", f"forearm.{side}"])
        hd = f["tail"]
        for k in range(3):
            C.cone(f"Claw{side}{k}", tuple(hd), tuple(hd + V((0.04 * (k - 1), -0.08, -0.12))), 0.02, "ice", f"forearm.{side}",
                   segs=4)
