"""Gluttonous Dreamer (Dark Moon, 6, legend): a colossal sleepwalking bull of the night pastures, coat
dappled with stars, a drooping nightcap snagged on its great horns, heavy-lidded dreaming eyes, and the
dreams it has swallowed floating up from its back as glowing bubbles."""
import math
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(hide="2a2a5a", hide2="4a4a8a", star="f0e8ff", horn="e8dcc0", cap="7a3aa8", capw="f0e8ff", eye="ffe08a",
              lid="1a1a40", nose="6a5a9a", ring="d8b83a", bub1="aef4ff", bub2="ffb8f0", bub3="fff0a0", hoof="1a1028")
    C.attack = "ram"
    kits.quad(C, "hide", hip=(0.38, 0.95), chest=(-0.3, 1.05), neck=(-0.55, 1.08), head=(-0.86, 0.98),
              r_hip=0.44, r_chest=0.5, r_waist=0.48, r_neck=0.3, r_head=0.24, r_snout=0.18, r_leg=0.13, r_paw=0.15,
              knee=0.45, leg_x=0.32, tail=((0.75, 0.9), (0.85, 0.55)), r_tail=0.05, muscle=1.3, head_drop=0.06, jaw=False)
    at = C.at
    import random
    rnd = random.Random(6)
    for k in range(16):
        x, y = rnd.uniform(-0.4, 0.4), rnd.uniform(-0.5, 0.55)
        C.decal(f"Dapple{k}", x, 3, (0.05, 0.05, 0.02), "star" if k % 3 else "hide2", "chest" if y < 0.04 else "hips",
                dir=(0, 0, -1), y=y)
    C.ellipsoid("Muzzle", at("snout", 0, -0.04, -0.02), (0.17, 0.12, 0.12), "nose", "head")
    C.lathe("NoseRing", [(0.06, 0.0), (0.07, 0.01), (0.06, 0.02)], "ring", "head", segs=14)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(V(at("nose", 0, -0.12, -0.08))) @
                                  __import__("mathutils").Matrix.Rotation(1.57, 4, 'X'))
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.15, -0.1, 0.02, mx), (0.05, 0.03, 0.03), "eye", "head")
        C.box(f"Lid{mx}", at("brow", 0.15, -0.11, 0.045, mx), (0.12, 0.06, 0.045), "lid", "head", rot=(15, 0, -10 * mx),
              bevel=0.5)
        C.ellipsoid(f"Ear{mx}", at("cran", 0.26, 0.04, 0.0, mx), (0.12, 0.05, 0.06), "hide", "head", rot=(0, 20 * mx, 0))
        # great curved horns
        base = V(at("cran", 0.16, 0.0, 0.12, mx))
        C.tube(f"Horn{mx}", [base, base + V((0.25 * mx, 0.05, 0.08)), base + V((0.42 * mx, -0.08, 0.28)),
                             base + V((0.38 * mx, -0.2, 0.42))], [0.08, 0.06, 0.04, 0.005], "horn", "head")
    # nightcap snagged on the right horn
    base = V(at("cran", 0.0, 0.05, 0.22))
    C.cone("Cap", tuple(base), tuple(base + V((0.35, 0.05, 0.25))), 0.2, "cap", "head", segs=12, smooth=True)
    C.lathe("CapBand", [(0.2, 0.0), (0.21, 0.06)], "capw", "head", segs=16)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(base) @
                                  __import__("mathutils").Matrix.Rotation(-0.95, 4, 'Y'))
    C.ellipsoid("CapPom", tuple(base + V((0.36, 0.05, 0.26))), (0.06, 0.06, 0.06), "capw", "head")
    # dream bubbles rising from its back
    C.bone("dreams", (0, 0, 1.4), (0, 0, 1.8), "chest", deform=True)
    for k, (x, y, z, s, m) in enumerate([(0.1, -0.1, 1.65, 0.1, "bub1"), (-0.15, 0.15, 1.85, 0.08, "bub2"),
                                         (0.05, 0.3, 2.05, 0.06, "bub3"), (-0.05, -0.25, 2.0, 0.05, "bub1")]):
        C.ellipsoid(f"Dream{k}", (x, y, z), (s, s, s), m, "dreams")
    C.extra_idle.append(lambda P, t: (P.l("dreams", z=0.08 * math.sin(6.283 * t)), P.r("dreams", 'Z', 25 * math.sin(6.283 * t))))
    for side in ("L", "R"):
        for tag in ("f", "b"):
            paw = C.bones[f"shin_{tag}.{side}"]["tail"]
            C.lathe(f"Hoof{tag}{side}", [(0.15, 0.0), (0.16, 0.07), (0.13, 0.12)], "hoof", f"shin_{tag}.{side}", segs=12)
            C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((paw.x, paw.y - 0.04, 0)))
