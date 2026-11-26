"""Bog Biter (Mushroom Forest, 2): a squat swamp croc-toad, all jaw: a huge underbite of fangs, bulging
yellow eyes on top, leech-slick hide with algae and a lily pad stuck to its back."""
from forge import kits


def build(C):
    C.palette(hide="3d5a34", belly="a3a86a", eye="ffd23a", pupil="0d0d0a", tooth="efe6c8", mouth="5a1a1e",
              algae="7fbf3a", pad="2f7a3a", leech="2a1a2a")
    C.attack = "bite"
    kits.quad(C, "hide", hip=(0.32, 0.48), chest=(-0.18, 0.52), neck=(-0.4, 0.58), head=(-0.82, 0.5),
              r_hip=0.3, r_chest=0.36, r_waist=0.3, r_neck=0.26, r_head=0.3, r_snout=0.2, r_leg=0.09, r_paw=0.1,
              knee=0.26, leg_x=0.34, tail=((0.65, 0.42), (0.95, 0.35), (1.18, 0.3)), r_tail=0.16, muscle=1.25)
    at = C.at
    # huge lower jaw with an underbite of fangs
    C.ellipsoid("Jaw", at("snout", 0, 0.0, -0.13), (0.26, 0.3, 0.09), "hide", "jaw", rot=(-6, 0, 0))
    C.ellipsoid("Mouth", at("snout", 0, -0.02, -0.07), (0.23, 0.26, 0.05), "mouth", "jaw")
    for k, x in enumerate((-0.18, -0.1, 0.0, 0.1, 0.18)):
        C.cone(f"Fang{k}", at("snout", x, -0.2 + abs(x) * 0.5, -0.1), at("snout", x * 1.1, -0.22 + abs(x) * 0.5, 0.07 - abs(x) * 0.2),
               0.035, "tooth", "jaw", segs=5)
    for k, x in enumerate((-0.14, 0.14)):
        C.cone(f"TopFang{k}", at("snout", x, -0.12, -0.02), at("snout", x, -0.14, -0.14), 0.03, "tooth", "head", segs=5)
    # bulging eyes on top of the head
    for mx in (-1, 1):
        C.ellipsoid(f"EyeBump{mx}", at("cran", 0.15, -0.05, 0.2, mx), (0.11, 0.11, 0.09), "hide", "head")
        C.ellipsoid(f"Eye{mx}", at("cran", 0.16, -0.12, 0.24, mx), (0.07, 0.05, 0.06), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", at("cran", 0.16, -0.165, 0.24, mx), (0.012, 0.01, 0.045), "pupil", "head")
    # pale belly
    C.decal("Belly", 0, 0.32, (0.34, 0.5, 0.06), "belly", "chest", dir=(0, 0, 1), y=0.05, spin=90)
    # algae clumps, a lily pad and leeches on the back
    for k, (x, y) in enumerate([(0.12, -0.1), (-0.15, 0.15), (0.05, 0.35), (-0.05, -0.25)]):
        C.decal(f"Algae{k}", x, 1.5, (0.11, 0.08, 0.03), "algae", "chest" if y < 0 else "hips", dir=(0, 0, -1), y=y,
                spin=30 * k)
    C.decal("Pad", 0.08, 1.5, (0.2, 0.2, 0.015), "pad", "hips", dir=(0, 0, -1), y=0.1)
    for k, (x, y) in enumerate([(0.3, 0.0), (-0.28, 0.25)]):
        C.decal(f"Leech{k}", x, 0.6, (0.05, 0.09, 0.03), "leech", "hips", dir=(-1 if x > 0 else 1, 0, 0), y=y)
    # ridge of knobbly scutes down the back and tail
    for k in range(7):
        y = -0.25 + k * 0.2
        z = C.surf(0, 2, dir=(0, 0, -1), y=y)[0].z if y < 0.6 else 0.5 - (y - 0.6) * 0.2
        C.ellipsoid(f"Scute{k}", (0, y, z + 0.01), (0.06, 0.08, 0.05), "hide", "chest" if y < 0 else ("hips" if y < 0.6 else "tail1"))
