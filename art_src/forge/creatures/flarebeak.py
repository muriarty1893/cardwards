"""Flarebeak (Ember Flats, 3): a fighting fire-cock of the lava fields, crimson-and-gold plumage, a comb of
living flame, a hooked molten beak, spurred legs and tail feathers that trail sparks."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(plume="b8201a", plume2="ffb03a", beak="ffd23a", eye="1a0a08", ring="fff4c0", leg="ffb03a", spur="2a1a14",
              fire="ff6a1a", hot="ffd03a", wattle="ff3a2a")
    C.attack = "bite"
    kits.quad(C, "plume", hip=(0.16, 0.6), chest=(-0.1, 0.72), neck=(-0.2, 0.98), head=(-0.36, 1.02),
              r_hip=0.2, r_chest=0.24, r_waist=0.21, r_neck=0.1, r_head=0.12, r_snout=0.05, r_leg=0.04, r_paw=0.05,
              knee=0.3, leg_x=0.11, tail=((0.32, 0.8), (0.42, 1.0)), r_tail=0.08, jaw=False, front=False)
    C.plan, C.hover = "flyer", 0.3
    at = C.at
    C.cone("Beak", at("snout", 0, 0.0, 0.0), at("snout", 0, -0.13, -0.06), 0.045, "beak", "head", segs=8, smooth=True)
    C.ellipsoid("Wattle", at("snout", 0, 0.0, -0.08), (0.035, 0.03, 0.06), "wattle", "head")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.07, -0.02, 0.02, mx), (0.025, 0.02, 0.025), "ring", "head")
        C.ellipsoid(f"Pupil{mx}", at("brow", 0.075, -0.035, 0.02, mx), (0.014, 0.01, 0.014), "eye", "head")
    props.flame(C, at("cran", 0, 0.0, 0.08), 0.14, "head", "fire", "hot", n=5, lean=(0, 0.35, 0), name="Comb")
    C.ellipsoid("Hackles", at("neck", 0, 0.0, 0.05), (0.14, 0.13, 0.16), "plume2", "neck")
    kits.wings(C, "plume", "plume", shoulder=(0.15, -0.05, 0.8), span=0.55, up=0.3, sweep=0.3, r=0.04, droop=0.4,
               fingers=3)
    for k in range(5):
        a = (k - 2) * 0.25
        b = V(C.anch["t0"])
        tip = b + V((a * 0.4, 0.3, 0.45 - abs(k - 2) * 0.08))
        C.tube(f"TailFeather{k}", [b, b + (tip - b) * 0.5 + V((0, 0.08, 0.05)), tip], [0.04, 0.035, 0.01],
               "plume2" if k % 2 else "plume", "tail2")
    props.flame(C, b + V((0, 0.35, 0.45)), 0.08, "tail2", "fire", "hot", n=3, lean=(0, 0.5, 0.2), name="Sparks")
    for side in ("L", "R"):
        sh = C.bones[f"shin_b.{side}"]
        C.cone(f"Spur{side}", tuple(sh["head"].lerp(sh["tail"], 0.6)), tuple(sh["head"].lerp(sh["tail"], 0.6) + V((0, 0.08, 0.02))),
               0.015, "spur", f"shin_b.{side}", segs=4)
