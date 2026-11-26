"""Pyrrhos, Spellstorm Stallion (Ember Flats, 8, legend): a black warhorse wreathed in fire. Sculpted: a
heavy draft-horse build with a deep chest, rounded muscular croup and a proudly arched neck, a long
chiselled head with flared nostrils, feathered fetlocks over burning hooves, a mane and tail of flame,
glowing rune brands and a single spiral horn crackling with spellfire."""
import math
from mathutils import Vector as V
from forge import props
from forge.sculpt import Clay, recolor, smoothstep, cracks


def horse(C, colors, texture=None, mane=False):
    """The sculpted horse shared by the horse legends: skeleton plus a clay body with groups hide, muzzle and
    feather (fetlocks); mane=True adds a sculpted crest of hair (group "mane"). Returns (body, legs)."""
    # ---- skeleton (faces -y)
    C.bone("root", (0, 0, 0), (0, 0, 0.3), deform=False)
    C.bone("hips", (0, 0.45, 1.08), (0, 0.0, 1.1), "root")
    C.bone("chest", (0, 0.0, 1.1), (0, -0.4, 1.16), "hips")
    C.bone("neck", (0, -0.4, 1.2), (0, -0.62, 1.5), "chest")
    C.bone("neck2", (0, -0.62, 1.5), (0, -0.76, 1.72), "neck")
    C.bone("head", (0, -0.76, 1.72), (0, -1.12, 1.4), "neck2")
    C.spine, C.neck, C.head = ["hips", "chest"], ["neck", "neck2"], "head"
    tail = [(0, 0.66, 1.16), (0, 0.84, 1.0), (0, 0.96, 0.76)]
    for i in range(2):
        C.bone(f"tail{i + 1}", tail[i], tail[i + 1], "hips" if i == 0 else f"tail{i}")
        C.tail.append(f"tail{i + 1}")
    legs = {}
    for side, sx in (("L", -1), ("R", 1)):
        fx, bx = 0.2 * sx, 0.21 * sx
        legs[side] = dict(
            f=[(fx, -0.4, 0.98), (fx, -0.44, 0.52), (fx, -0.42, 0.16), (fx, -0.46, 0.04)],
            b=[(bx, 0.46, 0.98), (bx, 0.38, 0.56), (bx, 0.5, 0.36), (bx, 0.46, 0.04)])
        f, b = legs[side]["f"], legs[side]["b"]
        C.bone(f"leg_f.{side}", f[0], f[1], "chest")
        C.bone(f"shin_f.{side}", f[1], f[3], f"leg_f.{side}")
        C.bone(f"leg_b.{side}", b[0], b[2], "hips")
        C.bone(f"shin_b.{side}", b[2], b[3], f"leg_b.{side}")
        C.legs += [(f"leg_f.{side}", f"shin_f.{side}", 0.0 if side == "L" else 0.5),
                   (f"leg_b.{side}", f"shin_b.{side}", 0.5 if side == "L" else 0.0)]

    # ---- sculpted body
    cl = Clay(C, "Body", res=0.03)
    cl.add((0, -0.3, 1.06), (0.27, 0.3, 0.3), group="hide")                    # deep chest
    cl.mirror((0.13, -0.5, 0.98), (0.13, 0.12, 0.17), group="hide")            # breast muscles
    cl.add((0, 0.05, 1.08), (0.27, 0.32, 0.26), group="hide")                  # barrel
    cl.add((0, 0.44, 1.12), (0.28, 0.28, 0.26), group="hide")                  # croup
    cl.mirror((0.15, 0.5, 1.02), (0.15, 0.22, 0.26), rot=(-10, 0, 0), group="hide")   # haunches
    cl.add((0, -0.36, 1.34), (0.12, 0.2, 0.08), group="hide")                  # withers
    cl.mirror((0.2, -0.34, 1.12), (0.1, 0.18, 0.18), rot=(-20, 0, 0), group="hide")   # shoulders
    # arched neck, thick at the base, crest on top
    cl.chain([(0, -0.42, 1.2), (0, -0.6, 1.48), (0, -0.74, 1.68)], [(0.2, 0.25, 0.24), (0.15, 0.18, 0.17),
                                                                   (0.125, 0.13, 0.13)], group="hide")
    cl.chain([(0, -0.36, 1.36), (0, -0.52, 1.6), (0, -0.7, 1.78)], [0.11, 0.1, 0.07], group="hide")
    # head: broad jowl, long flat face, soft muzzle, flared nostrils, eye sockets
    cl.add((0, -0.8, 1.66), (0.125, 0.14, 0.13), group="hide")
    cl.mirror((0.075, -0.84, 1.6), (0.065, 0.12, 0.1), group="hide")
    cl.chain([(0, -0.86, 1.68), (0, -1.0, 1.52), (0, -1.1, 1.4)], [(0.1, 0.08, 0.1), (0.085, 0.08, 0.085),
                                                                  (0.09, 0.08, 0.08)], group="hide")
    cl.add((0, -1.14, 1.36), (0.085, 0.06, 0.065), group="muzzle")
    cl.mirror((0.042, -1.19, 1.4), (0.024, 0.03, 0.024), group="muzzle", neg=True)
    cl.mirror((0.1, -0.88, 1.7), (0.03, 0.03, 0.026), group="hide", neg=True)
    cl.mirror((0.085, -0.9, 1.74), (0.05, 0.05, 0.025), rot=(0, 0, -15), group="hide")   # brow ridge
    cl.add((0, -1.14, 1.32), (0.055, 0.04, 0.008), group="muzzle", neg=True)   # mouth line
    for sx in (-1, 1):
        f, b = legs["L" if sx < 0 else "R"]["f"], legs["L" if sx < 0 else "R"]["b"]
        # foreleg: forearm muscle, knee, thin cannon, fetlock feathering
        cl.chain([f[0], f[1]], [0.11, 0.065], group="hide")
        cl.add(f[1], (0.065, 0.07, 0.06), group="hide")
        cl.chain([f[1], f[2]], [0.05, 0.045], group="hide")
        cl.add((f[2][0], f[2][1] + 0.01, 0.17), (0.07, 0.07, 0.07), group="feather")
        # hind leg: big gaskin, hock, cannon
        cl.chain([b[0], b[1]], [0.15, 0.09], group="hide")
        cl.chain([b[1], b[2]], [0.08, 0.06], group="hide")
        cl.add(b[2], (0.055, 0.065, 0.05), group="hide")
        cl.chain([b[2], (b[2][0], b[2][1] - 0.03, 0.16)], [0.05, 0.045], group="hide")
        cl.add((b[2][0], b[2][1] - 0.03, 0.17), (0.07, 0.07, 0.07), group="feather")
    cl.add((0, 0.66, 1.16), (0.07, 0.07, 0.07), group="hide")                  # tail root
    if mane:
        for k in range(9):
            t = k / 8
            p = V((0, -0.76, 1.86)).lerp(V((0, -0.34, 1.44)), t)
            sd = 1 if k % 2 else -1
            cl.add(tuple(p + V((0, 0.02, 0.03))), (0.07, 0.08, 0.08), group="mane")
            cl.chain([p, p + V((0.12 * sd, 0.08, -0.04)), p + V((0.2 * sd, 0.16, -0.24))], [0.085, 0.065, 0.025],
                     group="mane")
        cl.add((0, -0.86, 1.8), (0.06, 0.08, 0.05), group="mane")                      # forelock
    body = cl.build(colors, voxel=0.016, budget=11000, texture=texture or {"type": 'CLOUDS', "scale": 0.06,
                                                                           "strength": 0.006})
    return body, legs


def build(C):
    C.palette(hide="1c1416", fire="ff5a1a", hot="ffcf3a", rune="ffa02a", hoof="2e2a2a", horn="f2d8a0", eye="fff0a0",
              armor="56505c", gold="c8902a", socket="0a0404")
    C.plan, C.attack = "quad", "ram"
    body, legs = horse(C, {"hide": "1c1416", "muzzle": "2a1a18", "feather": "3a2018"})
    # ember glow under the skin: cracks brightest on the legs and chest, fading over the back
    recolor(body, lambda p, n: cracks(p, 0.12, 0.05, seed=3) * smoothstep(0.9, 0.3, p.z) * 0.9, "ff5a1a")
    recolor(body, lambda p, n: smoothstep(0.35, 0.1, p.z) * 0.8, "ff8a2a")
    recolor(body, lambda p, n: smoothstep(0.75, 1.0, n.z) * 0.35, "3a2a2a")

    # ---- crisp details
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.1 * mx, -0.895, 1.7), (0.022, 0.03, 0.018), "hot", "head", rot=(0, 0, 25 * mx))
        C.cone(f"Ear{mx}", (0.07 * mx, -0.76, 1.8), (0.1 * mx, -0.7, 1.96), 0.042, "hide", "head", segs=5)
        C.ellipsoid(f"Nostril{mx}", (0.043 * mx, -1.2, 1.4), (0.016, 0.01, 0.016), "fire", "head")
    base = V((0, -0.86, 1.78))
    tip = base + V((0, -0.24, 0.36))
    C.cone("Horn", tuple(base), tuple(tip), 0.05, "horn", "head", segs=8, smooth=True)
    for k in range(5):
        p = base.lerp(tip, 0.1 + 0.18 * k)
        C.ellipsoid(f"HornRing{k}", tuple(p), (0.045 - 0.008 * k,) * 2 + (0.01,), "rune", "head", rot=(-34, 0, 0))
    props.flame(C, tuple(tip + V((0, -0.01, 0.02))), 0.08, "head", "fire", "hot", n=3, name="HornFire")
    # mane of fire along the neck crest, a flaming tail
    pts = [tuple(V((0, -0.72, 1.82)).lerp(V((0, -0.36, 1.42)), t)) for t in (0.0, 0.2, 0.4, 0.6, 0.8, 1.0)]
    props.mane_of_fire(C, pts, 0.18, lambda i: "neck2" if i < 2 else "neck" if i < 5 else "chest", "fire", "hot")
    props.flame(C, (0, 0.7, 1.16), 0.28, "tail1", "fire", "hot", n=5, lean=(0, 1.0, 0.1), name="TailFire")
    props.flame(C, (0, 0.88, 0.9), 0.22, "tail2", "fire", "hot", n=4, lean=(0, 0.5, -0.6), name="TailFire2")
    # war barding: a spiked chanfron over the face, a chest plate, gold rims
    C.ellipsoid("Chanfron", (0, -1.03, 1.625), (0.11, 0.18, 0.04), "armor", "head", rot=(49, 0, 0))
    for k in range(2):
        b = V((0, -1.0 - 0.07 * k, 1.69 - 0.08 * k))
        C.cone(f"FaceSpike{k}", tuple(b), tuple(b + V((0, -0.09, 0.05))), 0.025, "gold", "head", segs=5)
    C.ellipsoid("Peytral", (0, -0.63, 1.02), (0.3, 0.07, 0.2), "armor", "chest", rot=(10, 0, 0))
    for mx in (-1, 0, 1):
        b = V((0.16 * mx, -0.69, 1.04 - 0.04 * abs(mx)))
        C.cone(f"ChestSpike{mx}", tuple(b), tuple(b + V((0.02 * mx, -0.12, 0.02))), 0.03, "gold", "chest", segs=5)
    # runes branded on the flanks
    for mx in (-1, 1):
        for k, (y, z) in enumerate([(0.3, 1.06), (-0.05, 1.04)]):
            C.decal(f"Rune{mx}{k}", 0, z, (0.08, 0.02, 0.02), "rune", "hips" if y > 0.1 else "chest",
                    dir=(-mx, 0, 0), y=y, spin=45 + 90 * k)
    for side in ("L", "R"):
        for tag in ("f", "b"):
            paw = V(legs[side][tag][3])
            C.ellipsoid(f"Hoof{tag}{side}", tuple(paw + V((0, -0.01, 0.02))), (0.07, 0.08, 0.05), "hoof",
                        f"shin_{tag}.{side}")
            props.flame(C, tuple(paw + V((0, 0.0, 0.08))), 0.09, f"shin_{tag}.{side}", "fire", "hot", n=3,
                        name=f"HoofFire{tag}{side}", lean=(0, 0.5, 0))
