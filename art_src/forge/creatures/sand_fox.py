"""Sand Fox (Sunny Dunes, 2): a lean fennec raider, pale gold fur, enormous ears, a black-tipped brush of
a tail and dark desert-hunter eyes. Built like Emberkit with one plain tail."""
from forge.creatures import emberkit


def build(C):
    C.palette(fur="e8c07a", fur2="fff4e0", soot="8a6a3a", eye="2a1a08", pupil="0a0604", tip="1a1208", nose="1a1208")
    emberkit.build(C, tails=1, fire=False)
    at = C.at
    for mx in (-1, 1):
        C.cone(f"BigEar{mx}", at("cran", 0.1, 0.04, 0.1, mx), at("cran", 0.24, 0.08, 0.46, mx), 0.1, "fur", "head", segs=6,
               smooth=True)
        C.cone(f"BigEarIn{mx}", at("cran", 0.1, 0.0, 0.12, mx), at("cran", 0.22, 0.04, 0.42, mx), 0.07, "fur2", "head",
               segs=6, smooth=True)
