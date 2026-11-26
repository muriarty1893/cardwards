"""Oasis Alpaca (Sunny Dunes, 4): a hardy desert alpaca that carries water to the wounded. Dressed from
Quaternius's CC0 Alpaca: a thick cream fleece, a woven teal-and-gold saddle blanket with clay water jugs
slung either side, and a sprig of palm on its head."""
import math
from mathutils import Vector as V

DRESS = dict(src="alpaca", height=1.6, head_bone="Head", rear_bone="Tail1",
             colors={"Main": "f4ead8", "Main_Light": "fffaf0", "Main_Dark": "d8c4a0", "Muzzle": "d8b890", "Hooves": "3a2a20"},
             anims={"Idle": "Idle", "Walk": "Walk", "Punch": "Attack_Headbutt", "HitReact": "Idle_HitReact_Left",
                    "Death": "Death", "Yes": "Idle_2"})


def dress(C, D):
    C.palette(blanket="2a8a8a", blanket2="ffcf3a", jug="c8683a", water="3ad8ff", palm="3a8a2a", rope="8a6a4a")
    t = D.top("Torso2", 0.5)
    C.ellipsoid("Blanket", tuple(t + V((0, 0, -0.04))), (0.2, 0.26, 0.06), "blanket", "Torso2")
    C.ellipsoid("BlanketTrim", tuple(t + V((0, 0, -0.05))), (0.21, 0.27, 0.035), "blanket2", "Torso2")
    for sx in (-1, 1):
        c = t + V((0.2 * sx, 0, -0.24))
        C.lathe(f"Jug{sx}", [(0.001, -0.09), (0.07, -0.06), (0.075, 0.02), (0.03, 0.08), (0.04, 0.1)], "jug", "Torso2", segs=12)
        C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(tuple(c)))
        C.ellipsoid(f"Water{sx}", tuple(c + V((0, 0, 0.105))), (0.028, 0.028, 0.008), "water", "Torso2")
        C.tube(f"Rope{sx}", [c + V((0, 0, 0.08)), t + V((0.12 * sx, 0, -0.02))], [0.008, 0.008], "rope", "Torso2")
    h = D.top("Head", 0.3)
    for k in range(3):
        a = math.radians(-30 + 30 * k)
        C.cone(f"Palm{k}", tuple(h), tuple(h + V((math.sin(a) * 0.12, 0.06, 0.12))), 0.02, "palm", "Head", segs=4)
