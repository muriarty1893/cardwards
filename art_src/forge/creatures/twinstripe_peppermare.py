"""Twinstripe Peppermare (Candy Hills, 5, legend): a peppermint warhorse striped red and white, twin
candy-cane horns, a mane of spun mint frosting and hooves of hard candy."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(white="f6f2f2", red="e8203a", mint="5affc0", dark="1a0a10", eye="3a1a2a", hoof="ff7aa8",
              gold="ffd23a")
    C.attack = "ram"
    kits.quad(C, "white", hip=(0.4, 0.98), chest=(-0.3, 1.05), neck=(-0.56, 1.5), head=(-0.95, 1.36),
              r_hip=0.3, r_chest=0.36, r_waist=0.28, r_neck=0.16, r_head=0.15, r_snout=0.11, r_leg=0.075,
              r_paw=0.1, knee=0.5, leg_x=0.2, tail=((0.62, 1.0), (0.82, 0.88)), r_tail=0.07, muscle=1.2,
              head_drop=0.06, jaw=False)
    at = C.at
    # twin swirl stripes: diagonal red bands wrapping the body and legs
    for k in range(7):
        y = -0.45 + 0.15 * k
        for mx in (-1, 1):
            C.decal(f"Stripe{k}{mx}", 0, 1.0, (0.06, 0.26, 0.03), "red", "chest" if y < 0.05 else "hips",
                    dir=(-mx, 0, 0), y=y, spin=35)
    for side in ("L", "R"):
        for tag in ("f", "b"):
            b = C.bones[f"shin_{tag}.{side}"]
            for t in (0.25, 0.65):
                p = b["head"].lerp(b["tail"], t)
                C.ellipsoid(f"LegStripe{tag}{side}{t}", tuple(p), (0.085, 0.085, 0.03), "red", f"shin_{tag}.{side}",
                            rot=(20, 0, 0))
            paw = b["tail"]
            C.lathe(f"Hoof{tag}{side}", [(0.1, 0.0), (0.11, 0.06), (0.08, 0.12)], "hoof", f"shin_{tag}.{side}", segs=12)
            C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((paw.x, paw.y - 0.04, 0)))
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.1, -0.04, 0.0, mx), (0.03, 0.04, 0.025), "eye", "head", rot=(0, 0, 30 * mx))
        C.box(f"Brow{mx}", at("brow", 0.09, -0.04, 0.05, mx), (0.08, 0.06, 0.02), "red", "head", rot=(0, 20 * mx, 0),
              bevel=0.4)
        # twin candy-cane horns curling forward
        base = V(at("brow", 0.07, 0.03, 0.1, mx))
        pts = [base, base + V((0.06 * mx, 0.02, 0.22)), base + V((0.05 * mx, -0.12, 0.36)), base + V((0.02 * mx, -0.22, 0.28))]
        C.tube(f"Horn{mx}", pts, [0.04, 0.035, 0.03, 0.02], "white", "head")
        for k in range(3):
            p = V(pts[0]).lerp(V(pts[1]), 0.3 + 0.35 * k) if k < 2 else V(pts[2])
            C.ellipsoid(f"HornStripe{mx}{k}", tuple(p), (0.045, 0.045, 0.015), "red", "head", rot=(30, 0, 0))
        C.ellipsoid(f"Nostril{mx}", at("nose", 0.04, -0.07, 0.0, mx), (0.018, 0.01, 0.015), "dark", "head")
    # frosting mane and tail
    n0, n1 = V(C.anch["chest"]), V(C.anch["nb"])
    for k in range(6):
        p = n1.lerp(n0, k / 5) + V((0, 0.05, 0.12))
        C.ellipsoid(f"Mane{k}", tuple(p), (0.07, 0.1, 0.09), "mint", "neck" if k < 3 else "chest", rot=(30, 0, 0))
        C.cone(f"ManeSpike{k}", tuple(p), tuple(p + V((0.04 * (k % 2 * 2 - 1), 0.15, 0.1))), 0.05, "mint",
               "neck" if k < 3 else "chest", segs=5)
    props.flame(C, C.anch["t0"], 0.16, "tail1", "mint", "white", n=4, lean=(0, 1.1, -0.2), name="Tail")
    C.ellipsoid("Bell", at("chest", 0, -0.36, -0.08), (0.06, 0.06, 0.07), "gold", "chest")
