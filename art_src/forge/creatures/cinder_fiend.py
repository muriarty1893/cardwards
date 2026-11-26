"""Cinder Fiend (Ember Flats, 7, legend): a winged fire demon, charcoal hide split by magma veins,
ram horns, a burning skull-face, ember bat wings, a whip tail tipped with flame."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(hide="241a1c", vein="ff5a1a", hot="ffc83a", horn="1a1416", bone="d8c8b0", wing="5a1a14",
              wingbone="2a1c1c", eye="fff2a0", claw="140f10")
    C.attack = "cast"
    kits.biped(C, "hide", hip=0.86, chest=1.36, neck=1.56, head_top=1.86, shoulder_x=0.36, hip_x=0.17,
               hand=(0.54, -0.12, 0.85), r_hip=0.24, r_waist=0.2, r_chest=0.36, r_neck=0.11, r_head=0.18,
               r_arm=0.09, r_hand=0.085, r_leg=0.11, r_foot=0.09, lean=0.18, knee_fwd=0.06)
    h = C.anch["head"]
    # burning skull face
    C.ellipsoid("Face", (0, h[1] - 0.12, h[2] - 0.02), (0.13, 0.1, 0.14), "bone", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.06 * mx, h[1] - 0.21, h[2] + 0.02), (0.035, 0.015, 0.02), "eye", "head",
                    rot=(0, 20 * mx, 0))
        C.box(f"Brow{mx}", (0.07 * mx, h[1] - 0.2, h[2] + 0.07), (0.11, 0.05, 0.03), "horn", "head", rot=(0, 25 * mx, 0),
              bevel=0.4)
        # big ram horns
        C.tube(f"Horn{mx}", [(0.1 * mx, h[1] - 0.02, h[2] + 0.12), (0.26 * mx, h[1] + 0.12, h[2] + 0.22),
                             (0.32 * mx, h[1] + 0.18, h[2] + 0.02), (0.26 * mx, h[1] + 0.0, h[2] - 0.06),
                             (0.3 * mx, h[1] - 0.1, h[2] + 0.06)], [0.06, 0.05, 0.04, 0.025, 0.004], "horn", "head")
        C.cone(f"Fang{mx}", (0.04 * mx, h[1] - 0.2, h[2] - 0.08), (0.04 * mx, h[1] - 0.21, h[2] - 0.15), 0.018, "bone",
               "head", segs=5)
    C.ellipsoid("Maw", (0, h[1] - 0.2, h[2] - 0.08), (0.06, 0.02, 0.02), "vein", "head")
    props.flame(C, (0, h[1] + 0.02, h[2] + 0.14), 0.18, "head", "vein", "hot", n=5, lean=(0, 0.5, 0))
    # magma veins
    for i, (x, z, sp, sz) in enumerate([(0.12, 1.3, 70, 0.12), (-0.12, 1.22, 110, 0.11), (0.0, 1.05, 90, 0.12),
                                        (0.2, 1.42, 30, 0.08), (-0.2, 1.42, 150, 0.08)]):
        C.decal(f"Vein{i}", x, z, (sz, 0.018, 0.018), "vein", "chest", spin=sp)
    for mx in (-1, 1):
        C.decal(f"LegVein{mx}", 0.17 * mx, 0.55, (0.08, 0.016, 0.016), "vein", "leg.L" if mx < 0 else "leg.R", spin=95)
    # wings, tail with flame tip, claws
    kits.wings(C, "wingbone", "wing", shoulder=(0.18, 0.12, 1.36), span=0.8, up=0.7, sweep=0.35, r=0.045, droop=0.6)
    C.bone("tail1", (0, 0.1, 0.82), (0, 0.45, 0.55), "hips")
    C.bone("tail2", (0, 0.45, 0.55), (0, 0.75, 0.42), "tail1")
    C.bone("tail3", (0, 0.75, 0.42), (0, 0.95, 0.55), "tail2")
    C.tail = ["tail1", "tail2", "tail3"]
    C.tube("Tail", [(0, 0.1, 0.82), (0, 0.45, 0.55), (0, 0.75, 0.42), (0, 0.95, 0.55)], [0.08, 0.055, 0.035, 0.02],
           "hide", None, allowed=["hips", "tail1", "tail2", "tail3"])
    props.flame(C, (0, 0.97, 0.56), 0.1, "tail3", "vein", "hot", n=3, lean=(0, 0.6, 0.2), name="TailFire")
    for side, mx in (("L", -1), ("R", 1)):
        hd = V(C.anch["hd" + side])
        for k in (-1, 0, 1):
            C.cone(f"Claw{side}{k}", hd + V((0.03 * k, -0.06, -0.03)), hd + V((0.04 * k, -0.12, -0.14)), 0.02,
                   "claw", f"forearm.{side}", segs=5)
    # fireball forming over the left palm
    hl = V(C.anch["hdL"])
    C.ellipsoid("Fireball", hl + V((0, -0.1, 0.12)), (0.1, 0.1, 0.1), "hot", "forearm.L")
    props.flame(C, hl + V((0, -0.1, 0.16)), 0.1, "forearm.L", "vein", "hot", n=4, name="Palm")
