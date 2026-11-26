"""Pyrrhos, Spellstorm Stallion (Ember Flats, 8, legend): a black warhorse wreathed in fire, a mane and
tail of flame, glowing rune brands, burning hooves and a single spiral horn crackling with spellfire."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(hide="1c1416", fire="ff5a1a", hot="ffcf3a", rune="ffa02a", hoof="2e2a2a", horn="f2d8a0",
              eye="fff0a0", armor="3a2a2a", gold="c8902a")
    C.attack = "ram"
    kits.quad(C, "hide", hip=(0.42, 1.0), chest=(-0.3, 1.08), neck=(-0.58, 1.55), head=(-0.98, 1.38),
              r_hip=0.32, r_chest=0.38, r_waist=0.3, r_neck=0.17, r_head=0.15, r_snout=0.11, r_leg=0.075,
              r_paw=0.1, knee=0.5, leg_x=0.2, tail=((0.65, 1.05), (0.85, 0.95)), r_tail=0.07, muscle=1.25,
              head_drop=0.06, jaw=False)
    at = C.at
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.1, -0.04, 0.0, mx), (0.03, 0.04, 0.022), "eye", "head", rot=(0, 0, 30 * mx))
        C.cone(f"Ear{mx}", at("cran", 0.07, 0.02, 0.1, mx), at("cran", 0.11, 0.06, 0.26, mx), 0.04, "hide", "head", segs=5)
        C.ellipsoid(f"Nostril{mx}", at("nose", 0.05, -0.06, 0.0, mx), (0.02, 0.012, 0.02), "fire", "head")
    # crackling spiral horn
    base = V(at("brow", 0, -0.02, 0.12))
    tip = base + V((0, -0.22, 0.38))
    C.cone("Horn", tuple(base), tuple(tip), 0.05, "horn", "head", segs=8, smooth=True)
    for k in range(4):
        p = base.lerp(tip, 0.15 + 0.2 * k)
        C.ellipsoid(f"HornRing{k}", tuple(p), (0.045 - 0.009 * k, 0.045 - 0.009 * k, 0.012), "rune", "head",
                    rot=(-30, 0, 0))
    # mane of fire down the neck, flaming tail
    n0, n1 = V(C.anch["chest"]), V(C.anch["nb"])
    pts = [tuple(n1.lerp(n0, t) + V((0, 0.06, 0.16 - 0.04 * t))) for t in (0.0, 0.25, 0.5, 0.75, 1.0)]
    props.mane_of_fire(C, pts, 0.15, lambda i: "neck" if i < 3 else "chest", "fire", "hot")
    props.flame(C, C.anch["t1"], 0.2, "tail2", "fire", "hot", n=5, lean=(0, 1.2, 0.3), name="TailFire")
    # rune brands on the flanks and a barding plate on the chest
    for mx in (-1, 1):
        for k, (y, z) in enumerate([(0.15, 1.05), (-0.1, 1.0)]):
            C.decal(f"Rune{mx}{k}", 0, z, (0.08, 0.02, 0.02), "rune", "hips" if y > 0 else "chest",
                    dir=(-mx, 0, 0), y=y, spin=45 + 90 * k)
    C.decal("ChestRune", 0, 1.0, (0.09, 0.09, 0.02), "rune", "chest", dir=(0, 1, 0))
    C.ellipsoid("Saddle", at("back", 0, 0, 0.02), (0.26, 0.24, 0.06), "armor", "chest")
    # burning hooves
    for side in ("L", "R"):
        for tag in ("f", "b"):
            paw = C.bones[f"shin_{tag}.{side}"]["tail"]
            C.lathe(f"Hoof{tag}{side}", [(0.1, 0.0), (0.11, 0.06), (0.08, 0.12)], "hoof", f"shin_{tag}.{side}", segs=12)
            C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((paw.x, paw.y - 0.04, 0)))
            props.flame(C, (paw.x, paw.y - 0.04, 0.1), 0.07, f"shin_{tag}.{side}", "fire", "hot", n=3,
                        name=f"HoofFire{tag}{side}", lean=(0, 0.4, 0))
