"""Blazehorn (Ember Flats, 5): a charging fire rhino, slabs of scorched armour plate, a great horn glowing
white-hot at the tip, a frill of flame behind its head and hooves that leave burning prints."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(hide="5a3a34", plate="3a2624", horn="2a1a18", hot="fff0a0", fire="ff6a1a", flame2="ffd03a", eye="ffcf3a",
              ember="ff5a14")
    C.attack = "ram"
    C.relax = 0.6
    kits.quad(C, "hide", hip=(0.34, 0.74), chest=(-0.26, 0.82), neck=(-0.5, 0.8), head=(-0.86, 0.66),
              r_hip=0.32, r_chest=0.4, r_waist=0.32, r_neck=0.24, r_head=0.25, r_snout=0.17, r_leg=0.085, r_paw=0.11,
              knee=0.36, leg_x=0.24, tail=((0.6, 0.72),), r_tail=0.04, muscle=1.1, head_drop=0.06, jaw=False)
    at = C.at
    base = V(at("nose", 0, -0.02, 0.08))
    C.cone("Horn", tuple(base), tuple(base + V((0, -0.14, 0.42))), 0.09, "horn", "head", segs=8, smooth=True)
    C.cone("HornTip", tuple(base + V((0, -0.1, 0.3))), tuple(base + V((0, -0.14, 0.43))), 0.04, "hot", "head", segs=8,
           smooth=True)
    C.cone("Horn2", at("brow", 0, -0.06, 0.12), at("brow", 0, -0.1, 0.26), 0.05, "horn", "head", segs=6, smooth=True)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.13, -0.02, 0.0, mx), (0.025, 0.02, 0.018), "eye", "head")
        C.cone(f"Ear{mx}", at("cran", 0.14, 0.06, 0.1, mx), at("cran", 0.2, 0.12, 0.22, mx), 0.05, "hide", "head", segs=5)
    # flame frill
    for k in range(5):
        x = -0.24 + 0.12 * k
        props.flame(C, at("cran", x, 0.08, 0.1 - abs(x) * 0.3), 0.1, "head", "fire", "flame2", n=3,
                    lean=(x * 1.5, 0.6, 0.2), name=f"Frill{k}")
    # scorched armour plates
    for k, y in enumerate((-0.3, -0.05, 0.2, 0.42)):
        loc = C.surf(0, 3, dir=(0, 0, -1), y=y)[0]
        if loc is not None:
            C.ellipsoid(f"Plate{k}", tuple(loc), (0.26 - 0.03 * abs(k - 1.5), 0.11, 0.05), "plate",
                        "chest" if y < 0.04 else "hips", rot=(10, 0, 0))
            C.ellipsoid(f"PlateEmber{k}", tuple(loc + V((0, 0.09, -0.02))), (0.22, 0.02, 0.03), "ember",
                        "chest" if y < 0.04 else "hips")
    for side in ("L", "R"):
        for tag in ("f", "b"):
            paw = C.bones[f"shin_{tag}.{side}"]["tail"]
            props.flame(C, (paw.x, paw.y - 0.04, 0.06), 0.06, f"shin_{tag}.{side}", "fire", "flame2", n=3,
                        name=f"Hoof{tag}{side}", lean=(0, 0.4, 0))
