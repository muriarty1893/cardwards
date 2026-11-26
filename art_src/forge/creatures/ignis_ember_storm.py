"""Ignis, the Ember Storm (Ember Flats, 9, legend): a great fire dragon, crimson scales over a molten
belly, a crown of swept horns, huge ember-veined wings and a tail ending in a blade of flame."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(scale="8a1a14", dark="3a0c0c", belly="ffb03a", horn="2a1a18", wing="c2381a", wingbone="4a1410",
              eye="fff2a0", fire="ff6a1a", hot="ffd03a", tooth="f2e6c8")
    C.attack = "dive"
    kits.quad(C, "scale", hip=(0.36, 0.78), chest=(-0.26, 0.9), neck=(-0.52, 1.7), head=(-0.92, 1.72),
              r_hip=0.33, r_chest=0.42, r_waist=0.3, r_neck=0.15, r_head=0.18, r_snout=0.11, r_leg=0.1, r_paw=0.12,
              knee=0.38, leg_x=0.26, tail=((0.7, 0.72), (1.0, 0.62), (1.2, 0.68)), r_tail=0.14, muscle=1.3,
              head_drop=0.02)
    C.plan, C.hover = "flyer", 0.45
    at = C.at
    # jaw, teeth, eyes, horns
    C.ellipsoid("Jaw", at("snout", 0, 0.02, -0.08), (0.1, 0.2, 0.045), "scale", "jaw")
    C.teeth("ToothU", [at("snout", x, -0.1 + abs(x), -0.06) for x in (-0.07, -0.035, 0.035, 0.07)], (0, 0, -1), 0.05,
            "tooth", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.1, -0.05, 0.03, mx), (0.035, 0.04, 0.022), "eye", "head", rot=(0, 0, 30 * mx))
        C.box(f"Brow{mx}", at("brow", 0.1, -0.05, 0.07, mx), (0.11, 0.08, 0.035), "dark", "head", rot=(0, 22 * mx, 0),
              bevel=0.4)
        C.tube(f"Horn{mx}", [V(at("cran", 0.09, 0.0, 0.1, mx)), V(at("cran", 0.18, 0.2, 0.2, mx)),
                             V(at("cran", 0.2, 0.42, 0.28, mx))], [0.05, 0.035, 0.004], "horn", "head")
        C.tube(f"Horn2{mx}", [V(at("cran", 0.13, 0.02, 0.0, mx)), V(at("cran", 0.24, 0.2, 0.04, mx))], [0.03, 0.004],
               "horn", "head")
        C.ellipsoid(f"Nostril{mx}", at("nose", 0.04, -0.07, 0.02, mx), (0.02, 0.012, 0.015), "fire", "head")
    # molten belly plates
    for k in range(6):
        y = -0.42 + 0.17 * k
        loc, nor = C.surf(0, -2, dir=(0, 0, 1), y=y)
        if loc is not None:
            C.ellipsoid(f"Plate{k}", tuple(loc), (0.2 - 0.012 * abs(k - 2), 0.08, 0.03), "belly",
                        "chest" if y < 0.05 else "hips")
    # spine ridge
    pts = [V(C.anch["nb"]).lerp(V(C.anch["chest"]), t) + V((0, 0, 0.14)) for t in (0.2, 0.6)]
    pts += [V((0, y, (C.surf(0, 3, dir=(0, 0, -1), y=y)[0] or V((0, 0, 1))).z)) for y in (-0.2, 0.05, 0.3)]
    C.spikes("Ridge", pts, lambda i, p: (0, 0.5, 1), [(0.05, 0.16), (0.06, 0.2), (0.07, 0.24), (0.07, 0.22), (0.06, 0.18)],
             "horn", bone=lambda i, p: "neck" if i < 2 else ("chest" if p.y < 0.05 else "hips"))
    # wings
    kits.wings(C, "wingbone", "wing", shoulder=(0.18, -0.12, 1.12), span=1.05, up=0.85, sweep=0.4, r=0.06, droop=0.75,
               fingers=4)
    # blade of flame at the tail tip
    props.flame(C, C.anch["t2"], 0.2, "tail3", "fire", "hot", n=4, lean=(0, 1.0, 0.2), name="TailFire")
    # embers leaking from the mouth
    props.flame(C, at("nose", 0, -0.08, -0.05), 0.06, "jaw", "fire", "hot", n=3, lean=(0, -0.3, 0), name="Breath")
