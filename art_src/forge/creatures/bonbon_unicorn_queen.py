"""Bonbon Unicorn Queen (Candy Hills, 7, legend): a regal war-unicorn. Sculpted: a powerful warhorse body
in a pearly coat, a flowing sculpted mane and tail of pink and violet cotton candy, a draped caparison of
candy-pink silk trimmed in gold and set with bonbon studs, a gilded chest plate, a spiralled sugar-glass
horn wound with gold and a jewelled bonbon crown."""
import math
from mathutils import Vector as V
from forge import props
from forge.sculpt import Clay, recolor, smoothstep
from forge.creatures.pyrrhos_spellstorm import horse


def build(C):
    C.palette(coat="fff0f6", gold="ffcf3a", gem="3ad8ff", horn="ffe8f8", armor="b83a7a", eye="3a1a4a",
              hoof="ffcf3a", bonbon="7a3a1a", mane="ff7ac0")
    C.plan, C.attack = "quad", "ram"
    body, legs = horse(C, {"hide": "fff0f6", "muzzle": "f8d8e8", "feather": "ffd8ec", "mane": "ff7ac0"}, mane=True,
                       texture={"type": 'CLOUDS', "scale": 0.05, "strength": 0.012})
    # cotton candy: pink and violet swirls through the mane, pearly sheen on the coat
    recolor(body, lambda p, n: (smoothstep(0.2, 0.9, math.sin(p.z * 30 + p.x * 20)) * 0.7
                                if (p - V((0, -0.55, 1.62))).length < 0.36 and abs(p.x) > 0.04 or p.z > 1.8 and p.y < -0.8
                                else 0.0), "c87aff")
    recolor(body, lambda p, n: smoothstep(0.6, 1.0, n.z) * 0.3, "fff8ff")

    # ---- crisp details
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.1 * mx, -0.895, 1.7), (0.026, 0.034, 0.022), "eye", "head", rot=(0, 0, 25 * mx))
        C.ellipsoid(f"Lash{mx}", (0.104 * mx, -0.9, 1.725), (0.03, 0.03, 0.008), "eye", "head", rot=(0, 0, 25 * mx))
        C.cone(f"Ear{mx}", (0.07 * mx, -0.76, 1.8), (0.1 * mx, -0.7, 1.96), 0.042, "coat", "head", segs=5)
    base = V((0, -0.86, 1.8))
    tip = base + V((0, -0.22, 0.46))
    C.cone("Horn", tuple(base), tuple(tip), 0.055, "horn", "head", segs=10, smooth=True)
    for k in range(6):
        C.ellipsoid(f"HornGold{k}", tuple(base.lerp(tip, 0.08 + 0.15 * k)), (0.05 - 0.008 * k,) * 2 + (0.01,), "gold",
                    "head", rot=(-26, 0, 0))
    props.crown(C, (0, -0.78, 1.86), 0.09, "gold", "head", points=5, height=0.08, m_gem="gem", tilt=-20)
    # sculpted cotton-candy tail
    tail = Clay(C, "Tail", res=0.02)
    for k in range(5):
        t = k / 4
        tail.add((0.03 * math.sin(k * 2), 0.68 + 0.2 * t, 1.12 - 0.42 * t), (0.13 - 0.02 * k, 0.12, 0.12),
                 group="a" if k % 2 else "b")
    tb = tail.build({"a": "ff7ac0", "b": "c87aff"}, voxel=0.014, budget=2500,
                    texture={"type": 'CLOUDS', "scale": 0.05, "strength": 0.02}, bone="tail1",
                    allowed=["tail1", "tail2"])
    # draped caparison: a silk sheet over the back, trimmed in gold, with bonbon studs
    cape = Clay(C, "Caparison", res=0.016)
    for k in range(11):
        a = math.radians(-80 + 16 * k)
        cape.add((math.sin(a) * 0.35, 0.1, 1.08 + math.cos(a) * 0.3), (0.09, 0.42, 0.025), rot=(0, math.degrees(a), 0),
                 group="silk")
    cb = cape.build({"silk": "b83a7a"}, voxel=0.012, relax=2, budget=4000, ao=0.3)
    recolor(cb, lambda p, n: smoothstep(0.86, 0.8, p.z), "ffcf3a")
    for mx in (-1, 1):
        for k in range(4):
            C.ellipsoid(f"Stud{mx}{k}", (0.37 * mx, -0.12 + 0.15 * k, 1.0), (0.012, 0.04, 0.04), "bonbon", "hips")
        C.ellipsoid(f"SkirtGem{mx}", (0.37 * mx, 0.1, 1.12), (0.015, 0.06, 0.06), "gem", "hips")
    C.ellipsoid("Peytral", (0, -0.62, 1.02), (0.28, 0.07, 0.18), "gold", "chest", rot=(10, 0, 0))
    for k in range(3):
        C.ellipsoid(f"ChestStud{k}", (-0.12 + 0.12 * k, -0.69, 1.04), (0.04, 0.025, 0.04), "bonbon", "chest")
    for side in ("L", "R"):
        for tag in ("f", "b"):
            paw = V(legs[side][tag][3])
            C.ellipsoid(f"Hoof{tag}{side}", tuple(paw + V((0, -0.01, 0.02))), (0.07, 0.08, 0.05), "hoof",
                        f"shin_{tag}.{side}")
