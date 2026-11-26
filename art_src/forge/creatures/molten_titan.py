"""Molten Titan (Ember Flats, 10): a colossus of cooled basalt slabs over a river of magma, a furnace
heart, a small hunched head with a molten visor slit and fists like boulders."""
import random
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(magma="ff5a14", hot="ffc23a", core="fff0a0", rock="2e2826", rock2="4a3f3a", ash="6a605a")
    C.attack = "slam"
    kits.biped(C, "magma", hip=0.88, chest=1.42, neck=1.6, head_top=1.85, shoulder_x=0.55, hip_x=0.24,
               hand=(0.72, -0.2, 0.45), r_hip=0.3, r_waist=0.3, r_chest=0.5, r_neck=0.17, r_head=0.17,
               r_arm=0.14, r_hand=0.12, r_leg=0.16, r_foot=0.16, lean=0.28, elbow_back=0.08)
    rnd = random.Random(3)
    # basalt slabs plastered over the magma body, gaps glowing between
    def slabs(bone, center, n, spread, size):
        c = V(center)
        for k in range(n):
            off = V((rnd.uniform(-1, 1) * spread[0], rnd.uniform(-1, 1) * spread[1], rnd.uniform(-1, 1) * spread[2]))
            d = off.normalized() if off.length > 0.01 else V((0, -1, 0))
            p = c + off
            C.box(f"Slab{bone}{k}", tuple(p + d * size * 0.2), tuple(size * rnd.uniform(0.75, 1.15) for _ in range(2)) +
                  (size * 0.45,), "rock" if k % 3 else "rock2", bone,
                  rot=(rnd.uniform(-25, 25), rnd.uniform(-25, 25), rnd.uniform(0, 90)), bevel=0.25, taper=(0.8, 0.8))
    ch = C.anch["chest"]
    slabs("chest", (0, ch[1], ch[2]), 14, (0.4, 0.3, 0.3), 0.3)
    slabs("hips", (0, 0, 0.95), 7, (0.28, 0.22, 0.15), 0.26)
    for side in ("L", "R"):
        for b, nm in ((f"arm.{side}", "el"), (f"forearm.{side}", "hd"), (f"leg.{side}", "kn"), (f"shin.{side}", "ft")):
            bb = C.bones[b]
            for t in (0.3, 0.75):
                p = bb["head"].lerp(bb["tail"], t)
                C.box(f"Limb{b}{t}", tuple(p + V((0, -0.05, 0))), (0.26, 0.26, 0.18), "rock", b,
                      rot=(rnd.uniform(-20, 20), rnd.uniform(-20, 20), rnd.uniform(0, 90)), bevel=0.25)
    # boulder fists
    for side in ("L", "R"):
        C.ellipsoid(f"Fist{side}", C.anch["hd" + side], (0.24, 0.24, 0.22), "rock2", f"forearm.{side}")
        hd = V(C.anch["hd" + side])
        C.decal(f"FistGlow{side}", hd.x, hd.z, (0.1, 0.02, 0.02), "magma", f"forearm.{side}", part=f"Fist{side}",
                y=None, spin=30)
    # furnace heart
    C.ellipsoid("Heart", (0, ch[1] - 0.5, ch[2] - 0.02), (0.15, 0.06, 0.15), "hot", "chest")
    C.ellipsoid("HeartCore", (0, ch[1] - 0.54, ch[2] - 0.02), (0.08, 0.04, 0.08), "core", "chest")
    # hunched head with a molten visor slit and smoking crest
    h = V(C.anch["head"])
    C.box("Helm", tuple(h + V((0, -0.02, 0.03))), (0.36, 0.34, 0.3), "rock", "head", bevel=0.3, taper=(0.85, 0.9))
    C.box("Visor", tuple(h + V((0, -0.19, 0.03))), (0.26, 0.05, 0.045), "core", "head", bevel=0.4)
    for k in range(3):
        C.cone(f"Crest{k}", tuple(h + V((0, 0.02 + 0.08 * k - 0.08, 0.18))), tuple(h + V((0, 0.14 + 0.08 * k, 0.42 - 0.06 * k))),
               0.06, "rock2", "head", segs=5)
    props.flame(C, h + V((0, 0.1, 0.2)), 0.12, "head", "magma", "hot", n=4, lean=(0, 0.7, 0), name="Smoke")
    # magma dripping from the shoulders
    for side, mx in (("L", -1), ("R", 1)):
        sh = V(C.anch["sh" + side])
        C.cone(f"Drip{side}", tuple(sh + V((0.1 * mx, -0.12, -0.05))), tuple(sh + V((0.12 * mx, -0.16, -0.35))), 0.05,
               "magma", f"arm.{side}", segs=6, smooth=True)
