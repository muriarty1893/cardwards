# Keywords, Dream Up picker and loose ends — design

Date: 2026-11-23. Approved in chat ("YES"). Builds the unfinished Rules 2.0 Stage 4
(`2026-11-16-rules-2-design.md` §7 "Mechanic visuals", plan Tasks 12–15) plus a few loose ends.

## Goals

The keyword rules already work in the engine, but on the board they are almost invisible, and
Dream Up never lets you choose. This batch makes every keyword readable at a glance (icon,
effect on the model, a moment when it triggers), adds the Dream Up choice, and fixes small
online and web issues. Success: a player who has never read the rules can tell which creature
has Guard, Bubble, Venom, etc. and why something just happened.

## 1. 40 life

- `GameState.START_HP` and `GameState.MAX_HP` become 40 (heals cap at 40). Nothing else changes.
- The rules stamp is regenerated, so the online version changes. The live web build can't
  match the new version until the browser game is re-exported (only when the user asks).

## 2. Keyword icons, badges, card text, tooltips

- `VisualDB.KEYWORD_ICONS`: one SVG per keyword in `Keywords.ORDER` plus `spell_power`, from
  game-icons.net (CC BY 3.0, credited in `assets/CREDITS.md`). Guard reuses `checked-shield.svg`.
- Creature tags show a row of small keyword icons (from `Rules.keywords_of`, so hush removes
  them and auras/gained keywords add them).
- Card text is a RichTextLabel: keyword names in bold, using `CardText.render(c, true)`.
  Hovering a card shows a tooltip listing the rule of each keyword it mentions.
- Combo: a card in your hand whose text has Combo glows gold once you have played a card
  this turn.
- Spell Power: the creature's tag shows a spark badge "+N".
- Star Shard: gold card frame.

## 3. Lasting keyword effects (on the model while the keyword is on)

`KeywordFx.attach/detach(view, kw)`, kept in sync with `Rules.keywords_of` and creature
state on every refresh:

| Keyword | Look |
|---|---|
| Guard | see-through hexagon shield wall in front of the creature, facing the enemy |
| Bubble | soap bubble around the body (fresnel rim, slow rainbow swirl), only while `bubble` is up |
| Hidden | see-through shimmer overlay on the body while `hidden` is true |
| Second Wind | small gold halo above the head until used |
| Venom | green drips falling from the body now and then |
| Flurry | double swoosh trail when it attacks |
| Dash | speed lines and dust when it lands on the turn it is played |

Leech and Spell Power show as badges only (their moments are in §4).
Every effect must compile on both renderers (Mobile and Compatibility) and must not drop the
HD 620 Low frame rate by more than ~2 fps on a full board.

## 4. One-shot moments

EventPlayer handlers: `bubble_popped` (bubble bursts into droplets + pop), `revealed`
(shimmer burst, overlay gone), `second_wind` (gold sparkles as it re-forms; halo gone),
`hushed` (grey ring wave, badges fade), `keyword_gained` (badge pops in, effect attaches),
`buffed` (tag flashes), `leeched` (red wisps fly to the hero portrait, which flashes green),
Venom kill (the victim tints green while dissolving).

## 5. Dream Up picker

- When playback reaches a Dream Up for you, three cards rise to the middle of the screen over
  a dim backdrop with the title "DREAM UP — choose one". Click one: it flies to your hand,
  the others fade away. A "PEEK" button hides the picker while held.
- Online: the turn clock keeps running while the picker is open. When it runs out, the
  picker takes the first card and the turn ends (the room's existing backstop rule).
- Rival's Dream Up: three face-down cards appear near the rival; one flies to their hand,
  the others fade. Their choice stays hidden.

## 6. Creature tags grow on hover

Hovering a creature (or its half-lane), or aiming an attack at it, scales its tag up and
shows the creature's name and each keyword icon with its name. The enlarged card still
appears at the side.

## 7. Room creation limit (server)

- Each client IP may create at most 5 rooms per minute and 30 per hour (`/host` and quick
  match both count). Over the limit: HTTP 429; the game shows "Too many rooms — try again
  in a minute".
- Counted in a small `Gate` Durable Object keyed by the IP (free plan). Redeployed with
  `npx wrangler deploy` using the saved login; if it has expired, ask the user to log in.

## 8. Small fixes

- The online panel's empty gap under JOIN ROOM goes away when idle.
- Symbol glyphs the web build can't draw (♥, ⚔, ✦) become icons (TextureRects / Sprite3D),
  so web and desktop match.

## Testing

TDD per task with the headless suite (`tests/run_tests.gd`), server vitest for the limit,
a shader compile check on both renderers, screenshots of each keyword and the picker, and an
fps check on Low. Commits stay local on `feat/keywords-picker`; no push or web export until
asked.
