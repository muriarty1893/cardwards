# Dream Isles: Living board design (tabletop part 2)

Date: 2026-11-18. Branch: `feat/tabletop`. Status: decided by Claude under the user's "full
permission" (the user was away; their list is below). Every rule here is a default the user can
overrule after playing.

## 1. The user's list (2026-11-18, after playing the tabletop build)

1. Rival's card hand and head twitch in a loop. → **done** (b9a876f)
2. Rival's card fan should show their real hand size, live. → **done** (b9a876f)
3. Camera: angle down a bit, more board, less rival. → **done** (b9a876f)
4. Lanes shouldn't be "three of one land + one splash" from the deck. Start **bare**; cards
   shape the lanes; synergies with the lane a card is placed in (e.g. buildings interact with
   the lane's environment when placed).
5. Animations for the lands and land interactions.
6. Tribes, and "if you control N of a type" synergies.
7. Spells interact with lands, not only creatures (e.g. a fireball on a frozen lane does
   something extra to the land).
8. Creature level-ups with effects, animations and visible changes.
9. A turnable scene, to see the table from other sides. → **done** (b9a876f)
10. Field spells (volcano, snowstorm, …).
11. Armour for your own hero, from spells and creatures.
12. Some creatures bring a house (decoration) and go into it now and then; more interactions
    like that.

## 2. Lanes: bare at the start, claimed by cards

- Every lane on both sides starts as **Meadow** (`CardData.Land.NEUTRAL`, shown as "Meadow":
  plain grass and wildflowers). `DeckData.lands` no longer sets the board (kept as the deck's
  colours for menus).
- **Claiming.** A creature or building played into a Meadow lane turns that lane into the card's
  land. A **building** also turns a lane of another land into its own (landmarks reshape the
  ground). Creatures never change a lane that already has a land. Neutral cards change nothing.
- **Levels (land requirement).** A level-N creature needs N lanes of its land *counting the lane
  it is played into* (that lane counts if it is Meadow or already the creature's land). So a
  level-1 creature can open any Meadow lane; a level-3 creature needs two lanes already claimed.
  Error text: "Needs 2 Frostpeak lanes".
- **Home.** A creature standing on its own land is *at home* and gets its land's quirk:

| Land | Quirk | Rule |
|---|---|---|
| Mushroom Forest | Rooted | Heals 1 at the start of your turn. |
| Ember Flats | Fired up | +1 ATK. |
| Candy Hills | Plump | +1 HP. |
| Frostpeak | Ice skin | Takes 1 less damage from attacks and hit-back (minimum 1). |

  Creatures on another land or on Meadow get nothing (no penalty).
- Lanes change land later only through buildings, land reactions (section 4) and field spells.
  Creatures already in play stay even if the lane stops counting for their level.

## 3. Buildings and the lane environment

- Placing a building claims or converts its lane (section 2) with the terraform animation.
- Buildings keep their land's ambient effect alive around them (kiln sparks, ice mist, spores,
  sprinkles).

## 4. Spells and lands: land reactions

When a spell's effect reaches a creature, the creature's lane may react with the spell's land.
Reactions show a name over the lane ("MELT!") and their own effect.

| Spell land → lane land | Reaction | Effect |
|---|---|---|
| Ember → Frostpeak | **Melt** | +1 damage; the lane thaws into Meadow (steam). |
| Ember → Mushroom Forest | **Wildfire** | 1 damage to the creatures in the neighbouring lanes on that side. |
| Ember → Candy Hills | **Caramel** | The creature is stuck in caramel (frozen). |
| Frost → Ember Flats | **Quench** | The lava cools: the lane turns into Meadow. |
| Mushroom → Mushroom Forest | **Bloom** | Heals 2 more. |
| Mushroom → Meadow | **Sprout** | The lane grows into Mushroom Forest. |

Reactions come only from spells (field spells included), once per target per effect. Melt and
Bloom change the amount; the others happen after the effect.

## 5. Tribes

Every creature has one tribe (shown on the card's type line and its tag tooltip). Tribes cross
lands, so mixed decks can chase them.

| Tribe | Creatures |
|---|---|
| Beast | Cinderpup, Blazehorn, Frostfang, Snowmite, Blizzard Titan, Glacier Tortoise, Bonbon Behemoth |
| Flyer | Ashmite, Flarebeak, Inferno Drake, Rimewing, Lollibat |
| Blob | Gumdrop, Taffy Snail, Jellywobble, Mossback |
| Sprout | Sporeling, Puffcap, Glimmer Morel, Rootstalker, Elder Shroomhulk |
| Spirit | Sugar Sprite, Iceling, Magmaw |

**Tribe bonuses** ("if you control N"): counted over your creatures; tier 1 at 2, tier 2 at 3+.

| Tribe | 2 | 3+ |
|---|---|---|
| Beast — Pack | Your Beasts have +1 ATK. | +2 ATK. |
| Flyer — Flock | Your Flyers deal +1 damage to the enemy hero. | +2. |
| Blob — Squish | Your Blobs have +2 HP. | +3 HP. |
| Sprout — Grove | Heal your hero 2 at the start of your turn. | 3. |
| Spirit — Haunt | Spell Power +1. | +2. |

**Card conditions.** EffectData gets `tribe` + `need`: the step runs only if you control at least
`need` *other* creatures of that tribe ("If you control 2 other Beasts: …"). A few cards get such
steps (section 10).

The HUD shows each side's active tribe bonuses as small chips under the hero corner.

## 6. Level-ups

- Creatures enter at Lv 1. **XP:** +1 each time it attacks and survives, +1 more when that
  attack destroys the defender. **Lv 2 at 2 XP, Lv 3 at 4 XP** (max).
- Each level: **+1 ATK, +1 HP**, and it heals 1. Hush keeps levels.
- `on_level_up` effects on some cards (section 10).
- Look: the model grows 12% per level; the tag shows ★ / ★★; Lv 3 gets a gold glow ring. Level-up
  plays a light column, sparkles, a hop and spin, "LEVEL UP!" text and a jingle.

## 7. Armour

- `PlayerState.armour` (max 20). Damage to a hero hits armour first. Fatigue ignores armour.
- Sources: op `armour` (who `own_hero`) on spells and creatures (section 10).
- HUD: a shield with the number beside the HP bar; gaining armour flashes a shield; absorbed
  damage shows as a blue number.

## 8. Field spells

- `CardData.field = true` spells. Playing one sets the **field** for both players; it stays until
  another field replaces it (the old one goes to its owner's discard).
- Field steps use `when` = `field_aura` (passive), `field_start` (start of each turn, for the
  player whose turn it is) and `field_end` (end of each turn, likewise).

| Field (land, cost) | Rules |
|---|---|
| Volcano (Ember, 4) | Creatures on Ember Flats have +1 ATK. End of each turn: 1 damage to each of the active player's creatures on Frostpeak (Melt does not apply). |
| Snowstorm (Frost, 4) | Creatures not on Frostpeak have −1 ATK (minimum 0). Ember Flats give no home quirk. |
| Spore Bloom (Mushroom, 3) | Start of each turn: the active player's first Meadow lane sprouts into Mushroom Forest. Creatures on Mushroom Forest have +1 HP. |
| Sugar Rain (Candy, 3) | Start of each turn: if the active player has a creature on Candy Hills, they draw a card. |

- Look: the room light tints, weather particles fall over the board (ash and embers, snow, glowing
  spores, sprinkles), lanes get an overlay (ash, snow dust), and a prop rises at the board's side
  (a toy volcano, a snow cloud, a ring of giant mushrooms, a candy cloud). A field banner names it.

## 9. Houses and life on the board (decoration only)

- Some small creatures bring a **house** when they are played: Mushroom → mushroom cottage,
  Ember → stone hut with a chimney, Candy → candy house, Frost → igloo. It pops up beside the
  roam zone (never on the building or boop spot).
- Now and then (every 12–25 s, never while busy) the creature walks to its door, goes in (shrinks
  through the door), the house wobbles, its window lights and its chimney puffs; 3–6 s later it
  comes out. When the creature dies, the house's windows go dark and it sinks away.
- Other idle life: creatures greet a neighbour (face it, hop, a heart), sniff a prop, and react to
  the field (shiver in Snowstorm, fan themselves in Volcano).

## 10. Card changes

New cards: Volcano, Snowstorm, Spore Bloom, Sugar Rain (fields); **Bark Shield** (Mushroom spell,
1: gain 4 armour); **Candy Shell** (Candy spell, 2: gain 3 armour, draw a card).

Changed cards (armour, tribe conditions, level-up steps):

| Card | Added |
|---|---|
| Mossback | On play: gain 2 armour. |
| Glacier Tortoise | On play: gain 3 armour. |
| Cinderpup | On play: if you control another Beast, give it +1/+1 (self). Level up: gain Flurry. |
| Rimewing | On play: if you control another Flyer, draw a card. |
| Taffy Snail | On play: if you control 2 other Blobs, gain 1 more magic. |
| Glimmer Morel | On play: if you control another Sprout, gain 3 armour. |
| Sugar Sprite | Level up: draw a card. |
| Flarebeak | Level up: deal 1 damage to the enemy hero. |
| Iceling | Level up: gain Bubble. |
| Sporeling | Level up: heal your hero 2. |
| Snowmite | Level up: freeze the opposing creature. |

Decks swap 2–3 cards each for the new ones (one field and one armour card per deck).

## 11. AI

Evaluation adds hero armour to HP, values claimed lanes of the lands it still holds cards for,
and sees every bonus through `Rules.effective_*` (home, tribes, levels, field). The planner needs
nothing new.

## 12. Out of scope

Tabletop Stage 3 (new UI kit, slim hand) stays next; Rules 2.0 Stage 4 and 5 after it. Web
re-export only when the user asks.
