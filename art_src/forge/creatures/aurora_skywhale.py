"""Aurora Skywhale (Frost Peaks, 10, legend): a vast whale swimming through the polar sky, a deep indigo
back marked with glowing aurora bands, barnacles of ice, long wing-like fins that ripple with green light."""
from mathutils import Vector as V
from forge import kits


def build(C):
    C.palette(back="1a2a5a", belly="c8d8f0", aur1="3affb0", aur2="a85aff", aur3="3ad8ff", ice="e8faff",
              eye="fff4c0", dark="060a1a")
    C.attack = "dive"
    kits.fish(C, "back", [(-0.66, 0.66, 0.18, 0.16), (-0.53, 0.52, 0.36, 0.3), (-0.26, 0.28, 0.44, 0.38),
                          (0.06, 0.18, 0.38, 0.34), (0.34, 0.26, 0.24, 0.21), (0.53, 0.46, 0.12), (0.64, 0.68, 0.06)],
              mid=3, hover=0.6, jaw=False)
    # belly grooves
    for k in range(6):
        y = -0.5 + 0.16 * k
        C.decal(f"Belly{k}", 0, -2, (0.24, 0.13, 0.05), "belly", "chest" if y < 0.0 else "hips", dir=(0, 0, 1), y=y)
    # glowing aurora bands across the back
    for k, (y, m) in enumerate([(-0.6, "aur1"), (-0.35, "aur2"), (-0.1, "aur3"), (0.15, "aur1"), (0.4, "aur2"), (0.65, "aur3")]):
        for mx in (-1, 1):
            C.decal(f"Aurora{k}{mx}", 0.15 * mx, 3, (0.04, 0.13, 0.025), m, "chest" if y < 0.12 else ("hips" if y < 0.55 else "tail1"),
                    dir=(0, 0, -1), y=y, spin=60 * mx)
    for mx in (-1, 1):
        C.ellipsoid(f"Eye{mx}", (0.31 * mx, -0.5, 0.46), (0.03, 0.05, 0.04), "eye", "head")
        C.box(f"Brow{mx}", (0.3 * mx, -0.5, 0.52), (0.04, 0.12, 0.03), "dark", "head", rot=(0, 0, 20 * mx), bevel=0.4)
        # long wing-fins
        C.membrane(f"Fin{mx}", [(0.36 * mx, -0.3, 0.15), (0.78 * mx, -0.12, -0.25), (0.8 * mx, 0.02, -0.32),
                                (0.38 * mx, -0.05, 0.08)][::(1 if mx > 0 else -1)], "back", "chest", thick=0.05)
        C.membrane(f"FinGlow{mx}", [(0.55 * mx, -0.2, -0.04), (0.78 * mx, -0.1, -0.24), (0.79 * mx, -0.02, -0.28),
                                    (0.56 * mx, -0.08, -0.06)][::(1 if mx > 0 else -1)], "aur1", "chest", thick=0.06)
    # ice barnacles
    import random
    rnd = random.Random(5)
    for k in range(10):
        x, y = rnd.uniform(-0.3, 0.3), rnd.uniform(-0.56, -0.28)
        C.decal(f"Barnacle{k}", x, 3, (0.04, 0.04, 0.035), "ice", "head" if y < -0.53 else "chest", dir=(0, 0, -1), y=y)
    # flukes
    C.membrane("Flukes", [(0, 0.58, 0.66), (-0.5, 0.74, 0.92), (-0.38, 0.64, 0.76), (0, 0.66, 0.72), (0.38, 0.64, 0.76),
                          (0.5, 0.74, 0.92)], "back", "tail3", thick=0.05)
    C.ellipsoid("Blowhole", (0, -0.3, 0.74), (0.05, 0.03, 0.02), "dark", "chest")
