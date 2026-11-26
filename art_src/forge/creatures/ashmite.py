"""Ashmite (Ember Flats, 2): a flying cinder mite, ash-grey armour plates over smouldering seams, wings of
heat-shimmer and a stinger glowing like a coal. Built like the Ember Hornet, in ash colours."""
from forge.creatures import ember_hornet


def build(C):
    C.palette(chitin="4a4448", stripe="ff4a1a", hot="ffb03a", wing="d8a080", eye="ffcf3a", leg="2a2426")
    ember_hornet.build(C)
    for mx in (-1, 1):
        C.cone(f"Horn{mx}", (0.06 * mx, -0.5, 1.08), (0.12 * mx, -0.62, 1.22), 0.03, "leg", "head", segs=5)
