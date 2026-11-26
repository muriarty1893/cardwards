"""Mawra, the Grave Glutton (Dark Moon, 5, legend): a squat, bloated ghoul-hound that is mostly mouth, a
split jaw lined with too many teeth, a drooling tongue, a stitched belly swollen with what it has eaten,
and tiny mad eyes."""
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(skin="6a5a7a", belly="a89ab8", stitch="2a1a2a", mouth="5a0a2a", tongue="d84a7a", tooth="f0e8d0",
              eye="d8ff3a", dark="0a060c", drool="c8f0ff", bone="e8dcc0")
    C.attack = "bite"
    C.relax = 1.0
    kits.quad(C, "skin", hip=(0.26, 0.6), chest=(-0.18, 0.68), neck=(-0.36, 0.72), head=(-0.66, 0.62),
              r_hip=0.34, r_chest=0.4, r_waist=0.42, r_neck=0.32, r_head=0.32, r_snout=0.24, r_leg=0.08, r_paw=0.1,
              knee=0.3, leg_x=0.28, tail=((0.5, 0.62), (0.62, 0.72)), r_tail=0.05, muscle=1.1, belly_drop=-0.04)
    at = C.at
    # the maw: a huge open split mouth lined with teeth
    C.ellipsoid("Maw", at("snout", 0, -0.05, -0.02), (0.3, 0.2, 0.1), "mouth", "head")
    C.ellipsoid("Lower", at("snout", 0, 0.02, -0.16), (0.3, 0.24, 0.09), "skin", "jaw")
    C.ellipsoid("Tongue", at("snout", 0, -0.1, -0.08), (0.12, 0.2, 0.04), "tongue", "jaw", rot=(-10, 0, 0))
    for k in range(9):
        x = -0.24 + 0.06 * k
        y = -0.18 + abs(x) * 0.6
        C.cone(f"ToothU{k}", at("snout", x, y, 0.06), at("snout", x, y - 0.02, -0.06), 0.03, "tooth", "head", segs=4)
        C.cone(f"ToothL{k}", at("snout", x * 0.95, y + 0.03, -0.12), at("snout", x * 0.95, y + 0.01, -0.02), 0.028, "tooth",
               "jaw", segs=4)
    C.tube("Drool", [V(at("snout", 0.12, -0.2, -0.12)), V(at("snout", 0.13, -0.22, -0.3))], [0.02, 0.012], "drool", "jaw")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("cran", 0.13, -0.18, 0.22, mx), (0.035, 0.025, 0.035), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", at("cran", 0.13, -0.2, 0.22, mx), (0.012, 0.01, 0.012), "dark", "head")
        C.cone(f"Ear{mx}", at("cran", 0.2, 0.05, 0.18, mx), at("cran", 0.36, 0.2, 0.12, mx), 0.07, "skin", "head", segs=6,
               smooth=True)
    # swollen stitched belly
    C.decal("Belly", 0, -1, (0.36, 0.42, 0.08), "belly", "chest", dir=(0, 0, 1), y=0.0, spin=90)
    for k in range(5):
        C.decal(f"Stitch{k}", 0, -1, (0.07, 0.012, 0.03), "stitch", "chest", dir=(0, 0, 1), y=-0.2 + 0.1 * k)
    # bones poking from its hide
    for k, (x, y) in enumerate([(0.18, -0.1), (-0.2, 0.15), (0.05, 0.3)]):
        loc, nor = C.surf(x, 3, dir=(0, 0, -1), y=y)
        if loc is not None:
            C.tube(f"Bone{k}", [loc - nor * 0.05, loc + nor * 0.2 + V((0.05, 0.05, 0))], [0.025, 0.02], "bone",
                   "chest" if y < 0.03 else "hips")
            C.ellipsoid(f"BoneEnd{k}", tuple(loc + nor * 0.21 + V((0.05, 0.05, 0))), (0.035, 0.035, 0.035), "bone",
                        "chest" if y < 0.03 else "hips")
