"""Dune Raptor (Sunny Dunes, 3): a sand-striped desert raptor, a crest of quills, a long stiff tail,
grasping clawed arms and the killing sickle-claw on each foot."""
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(hide="c8904a", stripe="6a3a1a", belly="f0d8a0", quill="b8301a", eye="ffd23a", pupil="0a0604", claw="1a1008",
              tooth="fff8e8")
    C.attack = "bite"
    kits.quad(C, "hide", hip=(0.2, 0.75), chest=(-0.2, 0.85), neck=(-0.36, 1.08), head=(-0.68, 1.12),
              r_hip=0.18, r_chest=0.18, r_waist=0.16, r_neck=0.09, r_head=0.12, r_snout=0.08, r_leg=0.08, r_paw=0.07,
              knee=0.45, leg_x=0.13, tail=((0.5, 0.82), (0.82, 0.86), (1.1, 0.9)), r_tail=0.1, muscle=1.3, front=False)
    at = C.at
    C.decal("Belly", 0, -1, (0.12, 0.25, 0.03), "belly", "chest", dir=(0, 0, 1), y=-0.05, spin=90)
    for k in range(6):
        y = -0.25 + 0.16 * k
        C.decal(f"Stripe{k}", 0, 3, (0.04, 0.2, 0.02), "stripe", "chest" if y < 0 else ("hips" if y < 0.4 else "tail1"),
                dir=(0, 0, -1), y=y, spin=90)
    C.ellipsoid("Jaw", at("snout", 0, 0.03, -0.06), (0.06, 0.14, 0.03), "belly", "jaw")
    C.teeth("Tooth", [at("snout", x, -0.1 + abs(x), -0.04) for x in (-0.04, -0.015, 0.015, 0.04)], (0, 0, -1), 0.035,
            "tooth", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.06, -0.03, 0.03, mx), (0.025, 0.025, 0.02), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", at("brow", 0.07, -0.045, 0.03, mx), (0.006, 0.008, 0.016), "pupil", "head")
        C.box(f"Brow{mx}", at("brow", 0.06, -0.03, 0.06, mx), (0.06, 0.05, 0.02), "stripe", "head", rot=(0, 25 * mx, 0),
              bevel=0.4)
        # small grasping arms
        sh = V(at("chest", 0.12, -0.12, -0.05, mx))
        C.tube(f"Arm{mx}", [sh, sh + V((0.04 * mx, -0.12, -0.1)), sh + V((0.03 * mx, -0.2, -0.04))], [0.035, 0.028, 0.02],
               "hide", "chest")
        for k in range(2):
            p = sh + V((0.03 * mx, -0.2, -0.04))
            C.cone(f"HandClaw{mx}{k}", tuple(p), tuple(p + V((0.02 * (k - 0.5), -0.06, -0.06))), 0.012, "claw", "chest", segs=4)
    for k in range(5):
        C.cone(f"Quill{k}", at("cran", 0, 0.02 + 0.06 * k, 0.06), at("cran", 0, 0.16 + 0.08 * k, 0.24 - 0.03 * k), 0.025,
               "quill", "head" if k < 3 else "neck", segs=4)
    for side in ("L", "R"):
        paw = V(C.bones[f"shin_b.{side}"]["tail"])
        C.tube(f"Sickle{side}", [paw + V((0, -0.06, 0.06)), paw + V((0, -0.12, 0.16)), paw + V((0, -0.18, 0.12))],
               [0.02, 0.015, 0.003], "claw", f"shin_b.{side}")
