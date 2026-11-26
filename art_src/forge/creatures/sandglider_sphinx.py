"""Sandglider Sphinx (Sunny Dunes, 6, legend): a winged lion-sphinx of the dunes, a striped gold-and-blue
pharaoh headdress, kohl-lined eyes, a braided beard, a jewelled collar and great falcon wings of gold."""
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(hide="e0a84a", hide2="c8883a", blue="1a3a8a", gold="ffd23a", kohl="0a0a14", eye="3affd8",
              wing="f0c050", wingtip="b8701a", gem="ff2a4a", mane="a85a1a")
    C.attack = "dive"
    kits.quad(C, "hide", hip=(0.34, 0.72), chest=(-0.26, 0.86), neck=(-0.44, 1.18), head=(-0.68, 1.2),
              r_hip=0.27, r_chest=0.34, r_waist=0.25, r_neck=0.16, r_head=0.19, r_snout=0.1, r_leg=0.085, r_paw=0.11,
              knee=0.38, leg_x=0.22, tail=((0.62, 0.72), (0.86, 0.85), (1.0, 1.05)), r_tail=0.05, muscle=1.25,
              head_drop=0.02, jaw=False)
    C.plan, C.hover = "flyer", 0.4
    at = C.at
    # pharaoh headdress: striped flaps framing the face
    cr = V(C.anch["cran"])
    C.ellipsoid("Nemes", tuple(cr + V((0, 0.04, 0.08))), (0.24, 0.22, 0.17), "gold", "head")
    for mx in (-1, 1):
        C.box(f"Flap{mx}", tuple(cr + V((0.19 * mx, 0.02, -0.16))), (0.07, 0.18, 0.36), "gold", "head",
              rot=(0, -8 * mx, 0), bevel=0.3, taper=(1.4, 1.2))
        for k in range(3):
            C.box(f"FlapStripe{mx}{k}", tuple(cr + V((0.205 * mx, 0.02, -0.06 - 0.1 * k))), (0.075, 0.19, 0.035), "blue",
                  "head", rot=(0, -8 * mx, 0), bevel=0.3)
        C.ellipsoid(f"Eye{mx}", at("brow", 0.085, -0.07, 0.03, mx), (0.035, 0.02, 0.022), "eye", "head")
        C.box(f"Kohl{mx}", at("brow", 0.1, -0.07, 0.03, mx), (0.1, 0.02, 0.012), "kohl", "head", rot=(0, -12 * mx, 0),
              bevel=0.3)
    for k in range(3):
        C.box(f"NemesStripe{k}", tuple(cr + V((0, 0.04, 0.17 - 0.06 * k))), (0.48 - 0.04 * k, 0.4, 0.025), "blue", "head",
              bevel=0.3)
    C.cone("Uraeus", tuple(cr + V((0, -0.2, 0.18))), tuple(cr + V((0, -0.24, 0.3))), 0.035, "gold", "head", segs=6)
    C.ellipsoid("UraeusGem", tuple(cr + V((0, -0.22, 0.2))), (0.025, 0.012, 0.025), "gem", "head")
    C.tube("Beard", [V(at("nose", 0, 0.02, -0.06)), V(at("nose", 0, 0.03, -0.2)), V(at("nose", 0, 0.0, -0.32))],
           [0.04, 0.035, 0.03], "blue", "head")
    # jewelled collar
    C.lathe("Collar", [(0.2, 0.0), (0.3, 0.05), (0.32, 0.08)], "gold", "chest", segs=24)
    C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation(V(at("neck", 0, 0.06, -0.12))) @
                                  __import__("mathutils").Matrix.Rotation(0.6, 4, 'X'))
    C.ellipsoid("CollarGem", at("chest", 0, -0.33, 0.12), (0.05, 0.025, 0.05), "gem", "chest")
    # falcon wings of gold
    kits.wings(C, "wingtip", "wing", shoulder=(0.18, -0.12, 1.08), span=0.9, up=0.65, sweep=0.38, r=0.05, droop=0.7,
               fingers=4)
    for side, mx in (("L", -1), ("R", 1)):
        tip = V(C.bones[f"wing2.{side}"]["tail"])
        for k in range(3):
            C.cone(f"Feather{side}{k}", tuple(tip - V((0.05 * mx * k, -0.08 * k, 0.08 * k))),
                   tuple(tip + V((0.2 * mx, 0.12 + 0.06 * k, -0.08 - 0.1 * k))), 0.05, "wingtip", f"wing2.{side}", segs=4)
    props.flame(C, C.anch["t2"], 0.08, "tail3", "mane", "hide2", n=3, lean=(0, 0.4, 0.4), name="TailTuft")
