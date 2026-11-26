"""Sugar Hoarder (Candy Hills, 4): a greedy candy vulture, bald pink head and a hooked beak, ragged wings,
clutching a bulging sack of stolen sweets with lollipops poking out."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(feather="5a2a5a", ruff="e8e0f0", head="ff8aa8", beak="ffc83a", eye="ff3a3a", dark="140a14",
              sack="c89a5a", rope="7a5a3a", pop1="ff4a8a", pop2="3ad8ff", stick="ffffff", wingtip="2a1030")
    C.attack = "dive"
    kits.quad(C, "feather", hip=(0.22, 0.62), chest=(-0.12, 0.78), neck=(-0.28, 1.05), head=(-0.55, 1.08),
              r_hip=0.26, r_chest=0.3, r_waist=0.27, r_neck=0.08, r_head=0.13, r_snout=0.06, r_leg=0.04, r_paw=0.05,
              knee=0.32, leg_x=0.13, tail=((0.45, 0.55), (0.62, 0.48)), r_tail=0.1, jaw=False, head_m="head", front=False)
    C.plan, C.hover = "flyer", 0.4
    at = C.at
    C.ellipsoid("Ruff", at("chest", 0, -0.02, 0.24), (0.24, 0.22, 0.12), "ruff", "chest")
    C.cone("Beak", at("snout", 0, -0.02, 0.02), at("snout", 0, -0.22, -0.1), 0.06, "beak", "head", segs=8, smooth=True)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.07, -0.02, 0.03, mx), (0.03, 0.02, 0.022), "eye", "head")
        C.box(f"Brow{mx}", at("brow", 0.07, -0.02, 0.07, mx), (0.07, 0.03, 0.02), "dark", "head", rot=(0, 25 * mx, 0),
              bevel=0.4)
    kits.wings(C, "feather", "feather", shoulder=(0.18, -0.08, 0.92), span=0.85, up=0.45, sweep=0.35, r=0.05,
               droop=0.5, fingers=4)
    for side, mx in (("L", -1), ("R", 1)):
        tip = V(C.bones[f"wing2.{side}"]["tail"])
        C.cone(f"Primary{side}", tuple(tip), tuple(tip + V((0.2 * mx, 0.1, -0.15))), 0.06, "wingtip", f"wing2.{side}",
               segs=5)
    # sack of stolen sweets clutched under the body
    s = V((0, -0.05, 0.25))
    C.ellipsoid("Sack", tuple(s), (0.24, 0.22, 0.24), "sack", "chest")
    C.lathe("SackTie", [(0.07, 0.0), (0.09, 0.06)], "rope", "chest", segs=12)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(s + V((0, 0, 0.22))))
    for k, (x, y, m) in enumerate([(-0.06, 0.0, "pop1"), (0.07, 0.03, "pop2"), (0.0, -0.06, "pop1")]):
        base = s + V((x, y, 0.22))
        top = base + V((x * 1.5, y * 1.5, 0.26))
        C.tube(f"Stick{k}", [base, top], [0.012, 0.012], "stick", "chest")
        C.ellipsoid(f"Pop{k}", tuple(top), (0.07, 0.025, 0.07), m, "chest", rot=(0, 0, 30 * k))
    for side in ("L", "R"):
        paw = V(C.bones[f"shin_b.{side}"]["tail"])
        for k in (-1, 0, 1):
            C.cone(f"Talon{side}{k}", tuple(paw + V((0.03 * k, -0.04, 0.02))), tuple(paw + V((0.05 * k, -0.1, -0.03))),
                   0.015, "dark", f"shin_b.{side}", segs=4)
