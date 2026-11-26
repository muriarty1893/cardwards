"""Taffy Serpent (Candy Hills, 3): a thick pulled-taffy cobra, banded pink and cream, its hood flared
wide and marked with a candy-swirl eye pattern, a forked licorice tongue and fangs of rock sugar."""
import math
from mathutils import Vector as V


def build(C):
    C.palette(taffy="ff7ab0", band="fff0d8", hood="8a1040", swirl="ffd0e8", eye="ffe23a", pupil="1a0a04",
              tongue="1a0a10", fang="ffffff")
    C.plan, C.attack = "biped", "bite"
    pts = [V((0.3, 0.3, 0.12)), V((-0.25, 0.25, 0.12)), V((-0.1, -0.15, 0.2)), V((0, -0.1, 0.6)), V((0, -0.2, 0.95)),
           V((0, -0.38, 1.05))]
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("coil", (0, 0.1, 0), (0, 0.1, 0.2), None)
    C.bone("hips", tuple(pts[2]), tuple(pts[3]), "root")
    C.bone("chest", tuple(pts[3]), tuple(pts[4]), "hips")
    C.bone("head", tuple(pts[4]), tuple(pts[5]), "chest")
    C.bone("jaw", tuple(pts[4] + V((0, -0.03, -0.06))), tuple(pts[5] + V((0, 0.0, -0.08))), "head")
    C.spine, C.head, C.jaw = ["hips", "chest"], "head", "jaw"
    radii = [0.08, 0.13, 0.15, 0.13, 0.11, 0.09]
    C.tube("Coil", pts[:3] + [pts[3]], radii[:4], "taffy", None, allowed=["coil", "hips"])
    C.tube("Neck", pts[2:6], radii[2:6], "taffy", None, allowed=["hips", "chest", "head"])
    for k in range(9):
        t = k / 8
        i = min(int(t * 5), 4)
        u = t * 5 - i
        p = pts[i].lerp(pts[i + 1], u)
        d = (pts[i + 1] - pts[i]).normalized()
        r = radii[i] + (radii[i + 1] - radii[i]) * u
        b = "coil" if i < 2 else (["hips", "hips", "chest", "head", "head"][i])
        C.lathe(f"Band{k}", [(r * 1.01, -0.025), (r * 1.06, 0.0), (r * 1.01, 0.025)], "band", b, segs=16)
        C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(p) @
                                      V((0, 0, 1)).rotation_difference(d).to_matrix().to_4x4())
    # flared hood with swirl markings
    hb = pts[4]
    C.membrane("Hood", [tuple(hb + V((0, 0.02, 0.12))), tuple(hb + V((0.26, 0.04, 0.0))), tuple(hb + V((0.22, 0.05, -0.28))),
                        tuple(hb + V((0, 0.06, -0.36))), tuple(hb + V((-0.22, 0.05, -0.28))), tuple(hb + V((-0.26, 0.04, 0.0)))],
               "hood", "chest", thick=0.04)
    for mx in (-1, 1):
        C.ellipsoid(f"HoodSwirl{mx}", tuple(hb + V((0.13 * mx, -0.0, -0.1))), (0.06, 0.02, 0.06), "swirl", "chest")
        C.ellipsoid(f"Eye{mx}", tuple(pts[5] + V((0.08 * mx, -0.02, 0.06))), (0.04, 0.035, 0.03), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", tuple(pts[5] + V((0.09 * mx, -0.05, 0.06))), (0.01, 0.01, 0.025), "pupil", "head")
        C.cone(f"Fang{mx}", tuple(pts[5] + V((0.035 * mx, -0.02, -0.03))), tuple(pts[5] + V((0.035 * mx, -0.03, -0.1))), 0.015,
               "fang", "head", segs=4)
    C.ellipsoid("Snout", tuple(pts[5] + V((0, 0.0, 0.0))), (0.13, 0.15, 0.09), "taffy", "head")
    C.tube("Tongue", [pts[5] + V((0, -0.08, -0.04)), pts[5] + V((0, -0.2, -0.06))], [0.012, 0.01], "tongue", "jaw")
    for mx in (-1, 1):
        C.cone(f"Fork{mx}", tuple(pts[5] + V((0, -0.2, -0.06))), tuple(pts[5] + V((0.03 * mx, -0.26, -0.06))), 0.01, "tongue",
               "jaw", segs=4)
