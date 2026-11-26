"""Magma Chieftain (Ember Flats, 6): a hulking basalt brute with lava cracks, horned skull crown,
tusks, obsidian pauldrons and a molten stone maul."""
from forge import kits


def build(C):
    C.palette(rock="2b2422", lava="ff6a1a", glow="ffc23a", bone="e8dcc0", obs="15121a", wrap="7a3a22",
              metal="4a4048")
    C.attack = "slam"
    kits.biped(C, "rock", hip=0.82, chest=1.38, neck=1.62, head_top=1.92, shoulder_x=0.48, hip_x=0.2,
               hand=(0.66, -0.12, 0.72), r_hip=0.3, r_waist=0.3, r_chest=0.5, r_neck=0.19, r_head=0.24,
               r_arm=0.15, r_hand=0.14, r_leg=0.16, r_foot=0.14, lean=0.16, elbow_back=0.12)
    at = C.at
    # glowing lava cracks across the chest and belly
    for i, (x, z, sp, sz) in enumerate([(0.18, 1.32, 70, 0.13), (-0.15, 1.25, 115, 0.11), (0.05, 1.1, 85, 0.12),
                                        (-0.12, 1.0, 60, 0.09), (0.22, 1.05, 105, 0.08), (0.3, 1.4, 40, 0.07),
                                        (-0.3, 1.38, 140, 0.07)]):
        C.decal(f"Crack{i}", x, z, (sz, 0.022, 0.02), "lava", "chest", spin=sp)
    # same cracks on the back and thighs
    for i, (x, z, sp, sz) in enumerate([(0.1, 1.3, 60, 0.13), (-0.12, 1.15, 120, 0.12), (0.0, 1.45, 90, 0.1)]):
        C.decal(f"BackCrack{i}", x, z, (sz, 0.022, 0.02), "lava", "chest", dir=(0, -1, 0), spin=sp)
    for mx in (-1, 1):
        C.decal(f"LegCrack{mx}", 0.22 * mx, 0.45, (0.09, 0.02, 0.02), "lava", "leg.R" if mx > 0 else "leg.L", spin=80)
    # face: glowing eyes under a heavy brow, tusks
    f = C.anch["head"]
    C.box("BrowRidge", (0, f[1] - 0.2, f[2] + 0.06), (0.32, 0.1, 0.07), "rock", "head", rot=(10, 0, 0), bevel=0.4)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.08 * mx, f[1] - 0.235, f[2] + 0.0), (0.05, 0.02, 0.024), "glow", "head",
                    rot=(0, 18 * mx, 0))
        C.horn(f"Tusk{mx}", (0.1 * mx, f[1] - 0.17, f[2] - 0.13), (0.15 * mx, f[1] - 0.24, f[2] + 0.02), 0.035,
               "bone", "head", bend=(0.02 * mx, -0.02, 0))
    C.ellipsoid("Mouth", (0, f[1] - 0.22, f[2] - 0.1), (0.1, 0.03, 0.02), "lava", "head")
    # skull crown with big curled horns
    C.ellipsoid("Skull", (0, f[1] - 0.02, f[2] + 0.17), (0.17, 0.17, 0.1), "bone", "head")
    for mx in (-1, 1):
        C.tube(f"Horn{mx}", [(0.13 * mx, f[1], f[2] + 0.2), (0.32 * mx, f[1] + 0.02, f[2] + 0.32),
                             (0.42 * mx, f[1] - 0.12, f[2] + 0.5), (0.36 * mx, f[1] - 0.22, f[2] + 0.62)],
               [0.07, 0.055, 0.035, 0.005], "bone", "head")
    # obsidian pauldrons with spikes
    for side, mx in (("L", -1), ("R", 1)):
        sh = C.anch["sh" + side]
        C.ellipsoid(f"Pauldron{side}", (sh[0] + 0.03 * mx, sh[1], sh[2] + 0.1), (0.24, 0.24, 0.14), "obs",
                    f"arm.{side}", rot=(0, 25 * mx, 0))
        for k in range(3):
            b = (sh[0] + (0.02 + 0.08 * k) * mx, sh[1] - 0.05 + 0.06 * k, sh[2] + 0.2)
            C.cone(f"PSpike{side}{k}", b, (b[0] + 0.07 * mx, b[1] + 0.02, b[2] + 0.2 - 0.03 * k), 0.045, "metal",
                   f"arm.{side}")
        hd = C.anch["hd" + side]
        C.lathe(f"Bracer{side}", [(0.15, -0.12), (0.16, 0.0), (0.14, 0.1)], "metal", f"forearm.{side}", segs=12)
        o = C.parts[-1][0]
        fa = C.bones[f"forearm.{side}"]
        import mathutils
        d = (fa["tail"] - fa["head"]).normalized()
        o.data.transform(mathutils.Matrix.Translation(fa["head"].lerp(fa["tail"], 0.6)) @
                         mathutils.Vector((0, 0, 1)).rotation_difference(d).to_matrix().to_4x4())
    # belt + loincloth
    p = C.anch["pelvis"]
    C.lathe("Belt", [(0.33, p[2] + 0.02), (0.34, p[2] + 0.1), (0.32, p[2] + 0.16)], "wrap", "hips", segs=20)
    C.ellipsoid("Buckle", (0, -0.33, p[2] + 0.09), (0.09, 0.04, 0.08), "bone", "hips")
    C.box("Loin", (0, -0.28, p[2] - 0.17), (0.26, 0.05, 0.34), "wrap", "hips", rot=(-8, 0, 0), bevel=0.2, taper=(1.2, 1))
    # molten maul in the right hand
    hd = C.anch["hdR"]
    C.tube("Haft", [(hd[0], hd[1] - 0.02, hd[2] + 0.18), (hd[0], hd[1] - 0.02, hd[2] - 0.2),
                    (hd[0], hd[1] - 0.02, hd[2] - 0.5)], [0.04, 0.04, 0.04], "wrap", "forearm.R")
    mz = hd[2] - 0.56
    C.box("MaulHead", (hd[0], hd[1] - 0.02, mz), (0.5, 0.32, 0.34), "obs", "forearm.R", bevel=0.3)
    for k, dx in enumerate((-0.26, 0.26)):
        C.box(f"MaulGlow{k}", (hd[0] + dx, hd[1] - 0.02, mz), (0.04, 0.26, 0.28), "lava", "forearm.R", bevel=0.3)
    C.box("MaulBand", (hd[0], hd[1] - 0.02, mz), (0.1, 0.34, 0.36), "metal", "forearm.R", bevel=0.2)
    # glowing knuckles
    hl = C.anch["hdL"]
    C.ellipsoid("FistGlow", (hl[0], hl[1] - 0.06, hl[2]), (0.08, 0.06, 0.06), "lava", "forearm.L")
