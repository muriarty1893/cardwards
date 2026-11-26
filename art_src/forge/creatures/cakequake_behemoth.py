"""Cakequake Behemoth (Candy Hills, 9): a hulking beast of layered cake, a back like a tiered wedding
cake with lit candles, frosting dripping down its sides, horns of hardened icing and a crushing chocolate
jaw full of sugar-cube teeth."""
import math
from mathutils import Vector as V
from forge import kits, props


def build(C):
    C.palette(sponge="e8b070", choc="4a2014", frost="fff0f8", pink="ff7ab8", cherry="e01a3a", candle="7ad8ff",
              flame="ffb03a", hot="fff0a0", tooth="ffffff", eye="ff2a6a", dark="1a0a08")
    C.attack = "ram"
    kits.quad(C, "choc", hip=(0.38, 0.82), chest=(-0.3, 0.9), neck=(-0.52, 0.95), head=(-0.9, 0.82),
              r_hip=0.42, r_chest=0.48, r_waist=0.44, r_neck=0.28, r_head=0.26, r_snout=0.18, r_leg=0.14, r_paw=0.16,
              knee=0.38, leg_x=0.34, tail=((0.75, 0.72), (0.95, 0.6)), r_tail=0.12, muscle=1.3, head_drop=0.06)
    at = C.at
    # sponge layer band around the body and frosting drips
    for k, y in enumerate((-0.3, 0.0, 0.3)):
        for mx in (-1, 1):
            C.decal(f"Sponge{k}{mx}", 0, 0.9, (0.04, 0.16, 0.04), "sponge", "chest" if y < 0.05 else "hips",
                    dir=(-mx, 0, 0), y=y, spin=90)
    # tiered cake on its back with candles
    b = V(C.anch["back"])
    for k, (r, hgt, m) in enumerate([(0.42, 0.18, "frost"), (0.3, 0.16, "pink"), (0.18, 0.14, "frost")]):
        z = b.z + 0.05 + sum([0.18, 0.16, 0.14][:k])
        C.lathe(f"Tier{k}", [(r, 0.0), (r, hgt), (r * 0.9, hgt + 0.02), (0.001, hgt + 0.02)], m, "chest" if k else "hips",
                segs=24)
        C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((0, b.y, z)))
        for j in range(8 - 2 * k):
            a = 2 * math.pi * j / (8 - 2 * k)
            p = V((math.cos(a) * r, b.y + math.sin(a) * r, z + hgt))
            C.cone(f"Drip{k}{j}", tuple(p), tuple(p + V((0, 0, -0.1 - 0.04 * (j % 2)))), 0.04, "frost" if m == "pink" else "pink",
                   "chest" if k else "hips", segs=5, smooth=True)
    top = b.z + 0.05 + 0.48 + 0.02
    for k in range(3):
        a = 2 * math.pi * k / 3
        p = V((math.cos(a) * 0.09, b.y + math.sin(a) * 0.09, top))
        C.tube(f"Candle{k}", [p, p + V((0, 0, 0.2))], [0.025, 0.025], "candle", "chest")
        props.flame(C, p + V((0, 0, 0.21)), 0.05, "chest", "flame", "hot", n=3, name=f"Wick{k}")
    C.ellipsoid("Cherry", (0, b.y + 0.0, top + 0.02), (0.06, 0.06, 0.06), "cherry", "chest")
    # head: icing horns, eyes, sugar-cube teeth
    for mx in (-1, 1):
        C.tube(f"Horn{mx}", [V(at("cran", 0.16, 0.0, 0.12, mx)), V(at("cran", 0.32, -0.05, 0.3, mx)),
                             V(at("cran", 0.3, -0.22, 0.42, mx))], [0.08, 0.05, 0.006], "frost", "head")
        C.ellipsoid(f"Eye{mx}", at("brow", 0.12, -0.12, 0.04, mx), (0.05, 0.03, 0.03), "eye", "head", rot=(0, 0, 25 * mx))
        C.box(f"Brow{mx}", at("brow", 0.12, -0.12, 0.1, mx), (0.15, 0.08, 0.05), "frost", "head", rot=(0, 25 * mx, 0),
              bevel=0.5)
    C.ellipsoid("Jaw", at("snout", 0, 0.02, -0.14), (0.2, 0.22, 0.07), "choc", "jaw")
    for k, x in enumerate((-0.14, -0.05, 0.05, 0.14)):
        C.box(f"Tooth{k}", at("snout", x, -0.16 + abs(x) * 0.4, -0.08), (0.06, 0.05, 0.06), "tooth", "jaw", bevel=0.2)
    for k, x in enumerate((-0.1, 0.1)):
        C.box(f"TopTooth{k}", at("snout", x, -0.17, -0.02), (0.06, 0.05, 0.07), "tooth", "head", bevel=0.2)
    C.ellipsoid("Nose", at("nose", 0, -0.12, 0.05), (0.07, 0.05, 0.05), "cherry", "head")
    for side in ("L", "R"):
        for tag in ("f", "b"):
            paw = C.bones[f"shin_{tag}.{side}"]["tail"]
            C.lathe(f"Paw{tag}{side}", [(0.17, 0.0), (0.17, 0.06), (0.15, 0.1)], "frost", f"shin_{tag}.{side}", segs=14)
            C.parts[-1][0].data.transform(__import__("mathutils").Matrix.Translation((paw.x, paw.y - 0.04, 0)))
