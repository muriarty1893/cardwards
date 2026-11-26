"""Bog Toad (Mushroom Forest, 3): a hulking marsh toad. Dressed from Quaternius's CC0 Frog (proper anatomy
and animation): slick dark-green skin with poison-yellow markings, orange eyes, a crown of cattail reeds and
a lily pad slung over its back."""
import math
from mathutils import Vector as V

DRESS = dict(src="frog", height=0.62, head_bone="Head", rear_bone="Hips",
             colors={"Green": "2f5a2a", "Yellow": "d8e03a", "Red": "ff8a1a", "Black": "0a0a08"},
             anims={"Idle": "Frog_Idle", "Walk": "Frog_Jump", "Punch": "Frog_Attack", "HitReact": "Frog_Idle",
                    "Death": "Frog_Death", "Yes": "Frog_Jump"})


def dress(C, D):
    C.palette(reed="7a5a2a", reedtop="4a2a14", pad="3a8a3a")
    h = D.top("Head", 0.4)
    for k in range(5):
        a = math.pi * (0.2 + 0.6 * k / 4)
        b = h + V((math.cos(a) * 0.08, 0.04 - math.sin(a) * 0.02, -0.01))
        top = b + V((math.cos(a) * 0.04, 0.03, 0.22 + 0.04 * (k % 2)))
        C.tube(f"Reed{k}", [b, top], [0.008, 0.006], "reed", "Head")
        C.ellipsoid(f"ReedTop{k}", tuple(top - V((0, 0, 0.04))), (0.018, 0.018, 0.05), "reedtop", "Head")
    b = D.top("Back", 0.5)
    C.lathe("Pad", [(0.001, 0.0), (0.16, 0.0), (0.17, 0.012)], "pad", "Back", segs=16)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(tuple(b + V((0.02, 0.02, -0.01)))) @
                                  __import__("mathutils").Matrix.Rotation(0.25, 4, 'Y'))
