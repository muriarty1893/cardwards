"""Flame Tiki (Ember Flats, 3): a hovering carved war-totem, a snarling tiki face with a furnace mouth,
a crown of fire on top and two floating stone fists."""
from mathutils import Vector as V
from forge import props


def build(C):
    C.palette(wood="6a3a1f", dark="3a1f12", carve="a8642f", fire="ff6a1a", hot="ffd03a", core="fff0a0",
              stone="4a4040", glow="ff8a2a", tooth="f0e0c0")
    C.plan, C.attack, C.hover = "hover", "cast", 0.3
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0, 0.35), (0, 0, 0.8), "root")
    C.bone("chest", (0, 0, 0.8), (0, 0, 1.3), "hips")
    C.bone("head", (0, 0, 1.3), (0, 0, 1.75), "chest")
    C.spine, C.head = ["hips", "chest"], "head"
    for side, sx in (("L", -1), ("R", 1)):
        C.bone(f"arm.{side}", (0.36 * sx, 0, 1.15), (0.58 * sx, -0.05, 0.85), "chest")
        C.bone(f"forearm.{side}", (0.58 * sx, -0.05, 0.85), (0.62 * sx, -0.15, 0.6), f"arm.{side}")
        C.arms.append((f"arm.{side}", f"forearm.{side}", side))
    # the totem: stacked tapered blocks
    C.box("Base", (0, 0, 0.5), (0.5, 0.42, 0.42), "dark", "hips", bevel=0.25, taper=(1.1, 1.1))
    C.box("Body", (0, 0, 0.95), (0.6, 0.5, 0.56), "wood", "chest", bevel=0.2, taper=(1.12, 1.05))
    C.box("Head", (0, 0, 1.5), (0.7, 0.56, 0.6), "wood", "head", bevel=0.2, taper=(1.1, 1.0))
    # carved snarling face: heavy brow, glaring eyes, furnace mouth with teeth
    C.box("BrowL", (-0.15, -0.29, 1.66), (0.26, 0.08, 0.08), "dark", "head", rot=(0, -18, 0), bevel=0.3)
    C.box("BrowR", (0.15, -0.29, 1.66), (0.26, 0.08, 0.08), "dark", "head", rot=(0, 18, 0), bevel=0.3)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.15 * mx, -0.29, 1.57), (0.08, 0.03, 0.05), "hot", "head")
        C.ellipsoid(f"Cheek{mx}", (0.24 * mx, -0.29, 1.42), (0.07, 0.04, 0.05), "carve", "head")
    C.ellipsoid("Nose", (0, -0.31, 1.47), (0.06, 0.05, 0.08), "carve", "head")
    C.box("Mouth", (0, -0.28, 1.31), (0.42, 0.08, 0.14), "fire", "head", bevel=0.4)
    C.box("MouthCore", (0, -0.3, 1.31), (0.3, 0.06, 0.08), "core", "head", bevel=0.4)
    for k in range(5):
        x = -0.16 + 0.08 * k
        C.cone(f"ToothU{k}", (x, -0.315, 1.39), (x, -0.315, 1.3), 0.025, "tooth", "head", segs=4)
    # belly carving: a glowing sun glyph
    C.ellipsoid("Glyph", (0, -0.27, 0.95), (0.13, 0.03, 0.13), "glow", "chest")
    C.ellipsoid("GlyphIn", (0, -0.285, 0.95), (0.07, 0.02, 0.07), "core", "chest")
    for k in range(3):
        C.box(f"Band{k}", (0, 0, 0.72 + 0.48 * k), (0.66 + 0.02 * k, 0.54, 0.05), "carve", ["hips", "chest", "head"][k],
              bevel=0.4)
    # crown of fire and side flames
    props.flame(C, (0, 0.02, 1.78), 0.32, "head", "fire", "hot", n=6, lean=(0, 0.12, 0), m_core="core")
    for mx in (-1, 1):
        props.flame(C, (0.33 * mx, 0, 1.62), 0.14, "head", "fire", "hot", n=3, lean=(0.3 * mx, 0.1, 0), name=f"Ear{mx}")
        # floating stone fists with ember knuckles
        C.ellipsoid(f"Fist{mx}", (0.62 * mx, -0.15, 0.58), (0.13, 0.13, 0.12), "stone", f"forearm.{'L' if mx < 0 else 'R'}")
        C.ellipsoid(f"Knuckle{mx}", (0.62 * mx, -0.27, 0.6), (0.09, 0.04, 0.06), "glow", f"forearm.{'L' if mx < 0 else 'R'}")
    # embers trailing under the base
    props.flame(C, (0, 0, 0.32), 0.18, "hips", "fire", "hot", n=4, lean=(0, 0.1, -2.2), name="Trail")
