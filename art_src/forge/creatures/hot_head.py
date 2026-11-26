"""Hot Head (Ember Flats, 1): a short-fused fire imp whose whole head is a living flame, a charcoal body
with clenched glowing fists, stomping goat hooves and a permanent snarl in the blaze."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(body="2a2024", vein="ff5a1a", fire="ff6a1a", hot="ffd03a", core="fff4c0", eye="1a0a08", hoof="140c0c",
              horn="3a2a2a")
    C.attack = "swipe"
    kits.biped(C, "body", hip=0.45, chest=0.75, neck=0.88, head_top=1.1, shoulder_x=0.2, hip_x=0.1,
               hand=(0.32, -0.08, 0.45), r_hip=0.15, r_waist=0.13, r_chest=0.19, r_neck=0.08, r_head=0.15,
               r_arm=0.06, r_hand=0.07, r_leg=0.07, r_foot=0.07, skin_head=False, lean=0.05, knee_fwd=0.05)
    h = V((0, -0.06, 0.98))
    C.ellipsoid("HeadCore", tuple(h), (0.16, 0.15, 0.15), "hot", "head")
    props.flame(C, h + V((0, 0.02, 0.0)), 0.3, "head", "fire", "hot", n=7, lean=(0, 0.25, 0), m_core="core", spread=0.9)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", tuple(h + V((0.06 * mx, -0.14, 0.02))), (0.035, 0.015, 0.02), "eye", "head",
                    rot=(0, -20 * mx, 0))
        C.horn(f"Horn{mx}", tuple(h + V((0.1 * mx, 0, 0.08))), tuple(h + V((0.2 * mx, 0.06, 0.25))), 0.035, "horn", "head")
        hd = V(C.anch["hdL" if mx < 0 else "hdR"])
        C.ellipsoid(f"Fist{mx}", tuple(hd), (0.085, 0.085, 0.08), "vein", "forearm.L" if mx < 0 else "forearm.R")
    C.box("Snarl", tuple(h + V((0, -0.15, -0.07))), (0.12, 0.015, 0.03), "eye", "head", bevel=0.3)
    for k, (x, z) in enumerate([(0.08, 0.75), (-0.08, 0.65), (0.0, 0.55)]):
        C.decal(f"Vein{k}", x, z, (0.07, 0.015, 0.015), "vein", "chest", spin=60 + 30 * k)
    for side in ("L", "R"):
        ft = C.bones[f"shin.{side}"]["tail"]
        C.ellipsoid(f"Hoof{side}", (ft.x, ft.y - 0.03, 0.04), (0.07, 0.08, 0.05), "hoof", f"shin.{side}")
