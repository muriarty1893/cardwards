"""Sand Fox (Sunny Dunes, 2): a lean fennec raider, pale gold fur, enormous ears, a black-tipped brush of
a tail and dark desert-hunter eyes. Built like Emberkit with one plain tail."""
from forge.creatures import emberkit


def build(C):
    C.palette(fur="e8c07a", fur2="fff4e0", soot="8a6a3a", eye="2a1a08", pupil="0a0604", tip="1a1208", nose="1a1208")
    emberkit.build(C, tails=1, fire=False, big_ears=True)
