# Writes the new card .tres files (Sunny Dunes + 4 per other land).
import os, sys
OUT = sys.argv[1]
M, E, C, F, D = 0, 1, 2, 3, 5
CR, BU, SP = 0, 1, 2
# id, name, kind, land, level, cost, atk, hp, keywords, tribe, spell_power, field, effects
# effect: dict(when, op, amount, amount2, who, keyword, filter_kind, filter_land, combo)
def e(when, op, amount=0, who="own_hero", **kw):
    d = dict(when=when, op=op, amount=amount, who=who); d.update(kw); return d
CARDS = [
 # --- Sunny Dunes
 ("sand_scuttler", "Sand Scuttler", CR, D, 1, 1, 2, 3, ["sturdy"], "blob", 0, False, []),
 ("meerkeep", "Meerkeep", CR, D, 1, 2, 2, 3, ["bask"], "beast", 0, False, [e("on_boop", "armour", 1)]),
 ("sand_fox", "Sand Fox", CR, D, 1, 2, 3, 2, ["dash"], "beast", 0, False, []),
 ("sun_scarab", "Sun Scarab", CR, D, 1, 3, 3, 3, [], "flyer", 0, False, [e("on_play", "armour", 2)]),
 ("dune_raptor", "Dune Raptor", CR, D, 2, 3, 3, 3, [], "beast", 0, False, [e("on_play", "dream_up", 0, filter_land=D)]),
 ("sandwraith", "Sandwraith", CR, D, 2, 4, 4, 4, ["hidden", "sturdy"], "spirit", 0, False, []),
 ("oasis_alpaca", "Oasis Alpaca", CR, D, 2, 4, 3, 5, ["bask"], "beast", 0, False, [e("end_of_turn", "heal", 2)]),
 ("lamp_djinn", "Lamp Djinn", CR, D, 3, 6, 6, 7, [], "spirit", 1, False, [e("on_play", "dream_up", 0, filter_kind=SP)]),
 ("sun_obelisk", "Sun Obelisk", BU, D, 0, 2, 0, 0, [], "", 0, False, [e("aura", "lane_keyword", 0, "lane_creature", keyword="sturdy"), e("aura", "lane_atk", 1, "lane_creature")]),
 ("sandstone_watchtower", "Sandstone Watchtower", BU, D, 0, 3, 0, 0, [], "", 0, False, [e("start_of_turn", "armour", 2)]),
 ("sun_shield", "Sun Shield", SP, D, 0, 2, 0, 0, [], "", 0, False, [e("on_play", "buff", 2, "chosen_own_creature", amount2=2), e("on_play", "give_keyword", 0, "same_target", keyword="sturdy")]),
 ("sandstorm", "Sandstorm", SP, D, 0, 4, 0, 0, [], "", 0, False, [e("on_play", "damage", 2, "all_away_creatures")]),
 ("mirage", "Mirage", SP, D, 0, 1, 0, 0, [], "", 0, False, [e("on_play", "dream_up", 0, filter_kind=CR)]),
 ("heatwave", "Heatwave", SP, D, 0, 3, 0, 0, [], "", 0, True, [e("field_end", "damage", 1, "all_away_creatures")]),
 # --- Mushroom Forest
 ("bog_toad", "Bog Toad", CR, M, 1, 3, 2, 4, ["sturdy"], "beast", 0, False, []),
 ("leaf_finch", "Leaf Finch", CR, M, 1, 2, 2, 2, ["bask"], "flyer", 0, False, []),
 ("moss_oracle", "Moss Oracle", CR, M, 2, 4, 3, 4, [], "blob", 0, False, [e("on_play", "dream_up", 0, filter_kind=SP)]),
 ("seed_pod", "Seed Pod", SP, M, 0, 1, 0, 0, [], "", 0, False, [e("on_play", "dream_up", 0, filter_land=M)]),
 # --- Ember Flats
 ("ember_wyrmling", "Ember Wyrmling", CR, E, 2, 3, 3, 3, ["bask"], "flyer", 0, False, []),
 ("magma_hog", "Magma Hog", CR, E, 2, 4, 3, 5, ["sturdy"], "beast", 0, False, []),
 ("spark_scroll", "Spark Scroll", SP, E, 0, 1, 0, 0, [], "", 0, False, [e("on_play", "dream_up", 0, filter_land=E)]),
 ("kindle", "Kindle", SP, E, 0, 2, 0, 0, [], "", 0, False, [e("on_play", "damage", 3, "chosen_creature"), e("on_play", "dream_up", 0, filter_land=E, combo=True)]),
 # --- Candy Hills
 ("jelly_fish", "Jelly Fish", CR, C, 1, 2, 2, 2, ["bubble"], "blob", 0, False, []),
 ("taffy_serpent", "Taffy Serpent", CR, C, 1, 3, 2, 5, ["sturdy"], "blob", 0, False, []),
 ("cotton_sheep", "Cotton Sheep", CR, C, 2, 4, 3, 4, ["bask"], "beast", 0, False, []),
 ("lucky_wrapper", "Lucky Wrapper", SP, C, 0, 1, 0, 0, [], "", 0, False, [e("on_play", "dream_up", 0, filter_land=C)]),
 # --- Frostpeak
 ("snow_wolf", "Snow Wolf", CR, F, 1, 3, 3, 2, ["dash"], "beast", 0, False, []),
 ("snow_globe", "Snow Globe", SP, F, 0, 1, 0, 0, [], "", 0, False, [e("on_play", "dream_up", 0, filter_land=F)]),
 ("ice_armor", "Ice Armor", SP, F, 0, 2, 0, 0, [], "", 0, False, [e("on_play", "buff", 0, "chosen_own_creature", amount2=3), e("on_play", "give_keyword", 0, "same_target", keyword="sturdy")]),
 ("frost_cairn", "Frost Cairn", BU, F, 0, 2, 0, 0, [], "", 0, False, [e("aura", "opposing_atk", 1, "lane_creature")]),
]

def sn(x): return '&"%s"' % x
for (cid, name, kind, land, level, cost, atk, hp, kws, tribe, spow, field, effs) in CARDS:
    lines = ['[gd_resource type="Resource" script_class="CardData" format=3]', '',
             '[ext_resource type="Script" path="res://core/card_data.gd" id="1_card"]']
    if effs:
        lines.append('[ext_resource type="Script" path="res://core/effect_data.gd" id="2_eff"]')
    lines.append('')
    subs = []
    for i, ef in enumerate(effs):
        rid = "Eff_%s_%d" % (cid, i)
        subs.append(rid)
        lines.append('[sub_resource type="Resource" id="%s"]' % rid)
        lines.append('script = ExtResource("2_eff")')
        lines.append('when = %s' % sn(ef["when"]))
        lines.append('op = %s' % sn(ef["op"]))
        if ef.get("amount"): lines.append('amount = %d' % ef["amount"])
        if ef.get("amount2"): lines.append('amount2 = %d' % ef["amount2"])
        if ef.get("who", "own_hero") != "own_hero": lines.append('who = %s' % sn(ef["who"]))
        if ef.get("keyword"): lines.append('keyword = %s' % sn(ef["keyword"]))
        if "filter_kind" in ef: lines.append('filter_kind = %d' % ef["filter_kind"])
        if "filter_land" in ef: lines.append('filter_land = %d' % ef["filter_land"])
        if ef.get("combo"): lines.append('combo = true')
        lines.append('')
    lines.append('[resource]')
    lines.append('script = ExtResource("1_card")')
    lines.append('id = %s' % sn(cid))
    lines.append('display_name = "%s"' % name)
    if kind: lines.append('kind = %d' % kind)
    lines.append('land = %d' % land)
    if level: lines.append('level = %d' % level)
    lines.append('cost = %d' % cost)
    if atk: lines.append('attack = %d' % atk)
    if hp: lines.append('health = %d' % hp)
    if kws: lines.append('keywords = Array[StringName]([%s])' % ", ".join(sn(k) for k in kws))
    if spow: lines.append('spell_power = %d' % spow)
    if tribe: lines.append('tribe = %s' % sn(tribe))
    if field: lines.append('field = true')
    if effs: lines.append('effects = Array[ExtResource("2_eff")]([%s])' % ", ".join('SubResource("%s")' % r for r in subs))
    open(os.path.join(OUT, cid + ".tres"), "w").write("\n".join(lines) + "\n")
print(len(CARDS), "cards")
