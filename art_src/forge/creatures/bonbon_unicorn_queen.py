"""Bonbon Unicorn Queen (Candy Hills, 7, legend): a regal war-unicorn in gilded candy barding, a spiralled
sugar-glass horn, a flowing mane of pink cotton candy and a jewelled bonbon crown."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(coat="fff0f6", mane="ff7ac0", mane2="c87aff", gold="ffcf3a", gem="3ad8ff", horn="ffe8f8",
              armor="b83a7a", eye="3a1a4a", hoof="ffcf3a", bonbon="7a3a1a")
    C.attack = "ram"
    kits.quad(C, "coat", hip=(0.42, 1.02), chest=(-0.3, 1.1), neck=(-0.56, 1.6), head=(-0.94, 1.48),
              r_hip=0.31, r_chest=0.38, r_waist=0.29, r_neck=0.16, r_head=0.15, r_snout=0.11, r_leg=0.075,
              r_paw=0.1, knee=0.52, leg_x=0.2, tail=((0.65, 1.05), (0.88, 0.85)), r_tail=0.07, muscle=1.2,
              head_drop=0.06, jaw=False)
    at = C.at
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.1, -0.04, 0.0, mx), (0.032, 0.045, 0.028), "eye", "head", rot=(0, 0, 30 * mx))
        C.cone(f"Ear{mx}", at("cran", 0.07, 0.02, 0.1, mx), at("cran", 0.1, 0.06, 0.26, mx), 0.04, "coat", "head", segs=5)
    # sugar-glass horn with gold spiral
    base = V(at("brow", 0, -0.02, 0.12))
    tip = base + V((0, -0.2, 0.46))
    C.cone("Horn", tuple(base), tuple(tip), 0.055, "horn", "head", segs=10, smooth=True)
    for k in range(5):
        p = base.lerp(tip, 0.1 + 0.17 * k)
        C.ellipsoid(f"HornGold{k}", tuple(p), (0.05 - 0.009 * k, 0.05 - 0.009 * k, 0.01), "gold", "head", rot=(-25, 0, 0))
    props.crown(C, at("cran", 0, 0.04, 0.12), 0.09, "gold", "head", points=5, height=0.08, m_gem="gem", tilt=-20)
    # cotton candy mane and tail
    n0, n1 = V(C.anch["chest"]), V(C.anch["nb"])
    for k in range(7):
        p = n1.lerp(n0, k / 6) + V((0, 0.06, 0.1))
        C.ellipsoid(f"Mane{k}", tuple(p), (0.1, 0.12, 0.11), "mane" if k % 2 else "mane2", "neck" if k < 4 else "chest")
    for k in range(3):
        C.ellipsoid(f"Tail{k}", tuple(V(C.anch["t0"]).lerp(V(C.anch["t1"]), k / 2) + V((0, 0.05, -0.05 * k))),
                    (0.11 - 0.015 * k, 0.12, 0.13), "mane" if k % 2 else "mane2", "tail1" if k < 2 else "tail2")
    # gilded barding: chest plate, flank skirt and bonbon studs
    C.ellipsoid("Peytral", at("chest", 0, -0.22, -0.1), (0.26, 0.1, 0.16), "armor", "chest")
    C.ellipsoid("PeytralTrim", at("chest", 0, -0.27, -0.0), (0.24, 0.07, 0.04), "gold", "chest")
    for k in range(3):
        C.ellipsoid(f"Stud{k}", at("chest", -0.12 + 0.12 * k, -0.31, -0.1), (0.045, 0.03, 0.045), "bonbon", "chest")
    C.ellipsoid("Caparison", at("back", 0, 0.05, -0.06), (0.34, 0.42, 0.08), "armor", "chest")
    for mx in (-1, 1):
        C.box(f"Skirt{mx}", (0.33 * mx, 0.05, 0.92), (0.05, 0.7, 0.28), "armor", "hips", bevel=0.2)
        C.box(f"SkirtTrim{mx}", (0.35 * mx, 0.05, 0.78), (0.05, 0.72, 0.05), "gold", "hips", bevel=0.3)
        C.ellipsoid(f"SkirtGem{mx}", (0.37 * mx, 0.05, 0.92), (0.03, 0.07, 0.07), "gem", "hips")
    for side in ("L", "R"):
        for tag in ("f", "b"):
            paw = C.bones[f"shin_{tag}.{side}"]["tail"]
            C.lathe(f"Hoof{tag}{side}", [(0.1, 0.0), (0.11, 0.06), (0.08, 0.12)], "hoof", f"shin_{tag}.{side}", segs=12)
            C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((paw.x, paw.y - 0.04, 0)))
