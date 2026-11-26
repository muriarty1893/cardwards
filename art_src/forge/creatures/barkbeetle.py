"""Barkbeetle (Mushroom Forest, 3): a heavy stag beetle armoured in living bark, branching antler mandibles,
moss in the seams of its carapace and six thick knobbly legs."""
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(bark="4a3420", bark2="6a4a2a", moss="5f9a2e", eye="ffcf3a", leg="2a1e14", horn="7a5a3a", leaf="3a8a2a")
    C.attack = "ram"
    kits.quad(C, "leg", hip=(0.28, 0.42), chest=(-0.16, 0.46), neck=(-0.3, 0.46), head=(-0.55, 0.42),
              r_hip=0.2, r_chest=0.2, r_waist=0.2, r_neck=0.12, r_head=0.15, r_snout=0.1, r_leg=0.045, r_paw=0.05,
              knee=0.25, leg_x=0.3, tail=((0.42, 0.4),), r_tail=0.05, jaw=False, head_m="bark")
    at = C.at
    # bark carapace: two wing cases with a seam of moss
    for mx in (-1, 1):
        C.ellipsoid(f"Elytra{mx}", (0.15 * mx, 0.12, 0.56), (0.18, 0.4, 0.17), "bark2", "hips",
                    rot=(0, 10 * mx, 0))
        for k in range(3):
            C.decal(f"Ridge{mx}{k}", 0.15 * mx, 3, (0.03, 0.22, 0.02), "bark", "hips", part=f"Elytra{mx}",
                    dir=(0, 0, -1), y=0.05 + 0.08 * (k - 1))
    C.ellipsoid("Seam", (0, 0.12, 0.7), (0.04, 0.38, 0.04), "moss", "hips")
    C.ellipsoid("Pronotum", (0, -0.18, 0.56), (0.24, 0.17, 0.14), "bark", "chest")
    # antler mandibles
    for mx in (-1, 1):
        base = V(at("snout", 0.08, -0.04, 0.0, mx))
        pts = [base, base + V((0.12 * mx, -0.16, 0.1)), base + V((0.08 * mx, -0.32, 0.22)), base + V((-0.02 * mx, -0.38, 0.3))]
        C.tube(f"Mandible{mx}", pts, [0.04, 0.032, 0.022, 0.005], "horn", "head")
        C.tube(f"Prong{mx}", [V(pts[1]), V(pts[1]) + V((0.1 * mx, -0.06, 0.12))], [0.02, 0.004], "horn", "head")
        C.ellipsoid(f"Eye{mx}", at("brow", 0.11, -0.02, 0.02, mx), (0.03, 0.03, 0.025), "eye", "head")
        # middle legs (rigid on the hips/chest)
        C.tube(f"MidLeg{mx}", [V((0.18 * mx, 0.0, 0.4)), V((0.34 * mx, -0.02, 0.32)), V((0.38 * mx, 0.02, 0.02))],
               [0.04, 0.035, 0.025], "leg", "chest")
    C.ellipsoid("Leaf", (0.08, 0.3, 0.73), (0.07, 0.04, 0.015), "leaf", "hips", rot=(0, 0, 30))
