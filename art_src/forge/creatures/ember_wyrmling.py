"""Ember Wyrmling (Ember Flats, 3): a young fire dragon, all elbows and attitude, orange scales with a
lighter belly, stubby horns, small leathery wings and smoke curling from its nostrils."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(scale="e85a1a", belly="ffd08a", horn="3a2a24", wing="ff8a3a", wingbone="8a2a10", eye="fff2a0",
              pupil="1a0a08", fire="ff6a1a", hot="ffd03a", smoke="6a5a5a", tooth="fff4e0")
    C.attack = "dive"
    kits.quad(C, "scale", hip=(0.24, 0.5), chest=(-0.18, 0.6), neck=(-0.34, 0.9), head=(-0.66, 0.92),
              r_hip=0.2, r_chest=0.24, r_waist=0.19, r_neck=0.11, r_head=0.18, r_snout=0.1, r_leg=0.07, r_paw=0.08,
              knee=0.25, leg_x=0.18, tail=((0.5, 0.45), (0.75, 0.4), (0.92, 0.5)), r_tail=0.1, muscle=1.2)
    C.plan, C.hover = "flyer", 0.4
    at = C.at
    C.decal("Belly", 0, -1, (0.16, 0.3, 0.04), "belly", "chest", dir=(0, 0, 1), y=0.0, spin=90)
    C.ellipsoid("Jaw", at("snout", 0, 0.02, -0.07), (0.08, 0.13, 0.035), "belly", "jaw")
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", at("brow", 0.09, -0.06, 0.04, mx), (0.045, 0.035, 0.035), "eye", "head")
        C.ellipsoid(f"Pupil{mx}", at("brow", 0.1, -0.09, 0.04, mx), (0.01, 0.01, 0.028), "pupil", "head")
        C.box(f"Brow{mx}", at("brow", 0.09, -0.06, 0.085, mx), (0.08, 0.05, 0.02), "scale", "head", rot=(0, 25 * mx, 0),
              bevel=0.4)
        C.horn(f"Horn{mx}", at("cran", 0.08, 0.02, 0.1, mx), at("cran", 0.14, 0.18, 0.2, mx), 0.035, "horn", "head")
        C.cone(f"Fang{mx}", at("snout", 0.05, -0.08, -0.04, mx), at("snout", 0.05, -0.09, -0.1, mx), 0.015, "tooth", "head",
               segs=4)
        props.flame(C, at("nose", 0.03, -0.06, 0.03, mx), 0.04, "head", "smoke", "smoke", n=3, lean=(0, 0.3, 0.6),
                    name=f"Smoke{mx}")
    for k in range(4):
        y = -0.15 + 0.15 * k
        loc = C.surf(0, 3, dir=(0, 0, -1), y=y)[0]
        if loc is not None:
            C.cone(f"Ridge{k}", tuple(loc), tuple(loc + V((0, 0.06, 0.1))), 0.035, "horn", "chest" if y < 0.02 else "hips",
                   segs=4)
    kits.wings(C, "wingbone", "wing", shoulder=(0.12, -0.12, 0.74), span=0.6, up=0.35, sweep=0.25, r=0.035, droop=0.4,
               fingers=3)
    props.flame(C, C.anch["t2"], 0.08, "tail3", "fire", "hot", n=3, lean=(0, 0.6, 0.3), name="TailFire")
