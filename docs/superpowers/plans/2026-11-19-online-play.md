# Dream Isles Online Play Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Two players play Dream Isles against each other online (room codes + quick match) through a free
Cloudflare relay, with live blocking, a 50 s turn timer, rejoin and rematch.

**Architecture:** Lockstep — both games run the deterministic rules engine from the same seed and decks; a
rule-blind Cloudflare Durable Object numbers the moves, runs the attack→block handshake and the timers. A seat
mirror (`SeatView`) lets the seat-1 player see themselves as player 0 without touching the view. `match.gd`
gets rival drivers (`AiRival`, `OnlineRival`).

**Tech Stack:** Godot 4.7 / GDScript (headless test runner in `tests/`), TypeScript Cloudflare Worker + Durable
Objects (SQLite-backed, WebSocket Hibernation), Vitest + `@cloudflare/vitest-pool-workers`, wrangler.

**Spec:** `docs/superpowers/specs/2026-11-19-online-play-design.md`

## Global Constraints

- Godot tests: `godot --headless --path . --script res://tests/run_tests.gd -- --only=<substring>`; full suite
  without `--only` must stay at 0 failures (baseline 18974 passed). Test files are `tests/test_*.gd` extending
  `TestCase`, each test returns `true`.
- Server tests: `cd server && npx vitest run`.
- Timer values: turn 50 s, fuse shown at ≤ 15 s, block timeout 10 s, turn backstop 70 s of silence from the
  active seat, reconnect window 60 s, cleanup: claimed-unused 2 min, over 10 min, nobody connected 10 min.
- Limits: message ≤ 4096 bytes, ≤ 20 messages per second per socket (else close 1008). Name: trimmed, control
  characters removed, ≤ 16 chars, empty → `Dreamer`. Default local name `Dreamer` + 3 digits (100–999).
  Deck message: `name` ≤ 24 chars, `lands` 4 ints in 0..4, `cards` exactly 30 strings.
- Room codes: `^[A-Z]{3,5}-[0-9]{2}$` (e.g. `FROG-42`); clients normalize `frog42`, `FROG 42`, ` frog-42 `.
- Version string: `"n1-" + md5(...)` first 10 hex chars (`NetVersion.current()`); bump `n1` only on protocol
  changes.
- Action dict = `Action.to_dict()`: `{type, player, hand_index, lane, targets, hit, blocked, choice, target_lane}`;
  `Action.Type` PLAY_CARD=0, BOOP=1, ATTACK=2, CHOOSE=3, END_TURN=4; `Action.Hit` NORMAL=0, CRIT=1, GLANCE=2.
- Canonical engine: host = player 0. The view always shows the local player as player 0
  (`MatchController.HUMAN`).
- Every change to `core/*.gd` is followed by `godot --headless --path . --script res://tools/stamp_rules.gd`
  (from Task 2 on) before running tests.
- Commit after every task (`git commit` on `feat/online`, message ends with the Co-Authored-By line). No push and
  no `web/` export unless the user asks.
- `server/.gdignore` must exist so Godot never scans `server/node_modules`.

## Review Focus

1. **A room-made END_TURN crossing an in-flight move** (tab frozen, backstop fires as the player clicks): the room
   rejects the late `act`; the game unlocks input, plays the `auto` END_TURN, and stays in sync. → tests in Task 7
   (referee) and Task 11 (session).
2. **Rejoining during a pending block**: the defender gets `block_wanted` again, the attacker `blocking`. → Task 8.
3. **Messy codes and names** (`frog 42`, lowercase, emoji/control chars, 40-char names, empty): normalized or
   refused with a message, never a crash. → Task 6 (server), Task 12 (client).
4. **An illegal custom deck picked for online** (29 cards after editing): refused in the panel before connecting.
   → Task 14.
5. **REMATCH after the rival left or after a desync**: the button is off with a reason, never a stuck "Waiting".
   → Task 9 (referee), Task 13 (results).

---

## Stage 1 — No network (vs AI unchanged)

### Task 1: Engine additions — setup `first`, state digest, deck codec

**Files:**
- Modify: `core/rules.gd:8-31` (`setup`)
- Modify: `core/game_state.gd` (add `digest`)
- Create: `core/deck_codec.gd`
- Test: `tests/test_net_core.gd`

**Interfaces:**
- Produces: `Rules.setup(deck_a: DeckData, deck_b: DeckData, seed: int, first: int = -1) -> GameState` — the
  `randi_range(0, 1)` roll always runs; `first >= 0` replaces its result.
- Produces: `GameState.digest() -> String` — 32-hex md5 over every field of the state (all `PlayerState`,
  `LaneState`, `CreatureState` fields, card ids for card references, `pending_choice` ids, `field` id, `rng.seed`
  and `rng.state`).
- Produces: `DeckCodec.encode(d: DeckData) -> Dictionary` (`{"name": String, "lands": Array, "cards": Array}` of
  id Strings); `DeckCodec.check(d: Variant) -> String` ("" when fine; otherwise a player-facing reason: shape,
  unknown card id, or the `DeckStore.validate` message); `DeckCodec.decode(d: Dictionary, id: StringName) ->
  DeckData` (call only after `check` returned "").

- [ ] **Step 1: Write the failing tests** in `tests/test_net_core.gd`:

```gdscript
func test_setup_first_keeps_shuffles() -> bool:
	var a := CardDB.deck(&"blaze_rush"); var b := CardDB.deck(&"deep_freeze")
	var s1 := Rules.setup(a, b, 99)
	var forced := 1 - s1.first_player
	var s2 := Rules.setup(a, b, 99, forced)
	assert_eq(s2.first_player, forced, "first is forced")
	assert_eq(_ids(s2.players[0].deck), _ids(s1.players[0].deck), "deck 0 shuffle unchanged")
	assert_eq(_ids(s2.players[1].deck), _ids(s1.players[1].deck), "deck 1 shuffle unchanged")
	assert_eq(s2.rng.state, s1.rng.state, "rng stream unchanged")
	assert_true(s2.players[1 - forced].hand.any(func(c: CardData) -> bool: return c.id == &"star_shard"), "second player gets the Star Shard")
	return true

func test_digest_stable_and_sensitive() -> bool:
	var s := Rules.setup(CardDB.deck(&"blaze_rush"), CardDB.deck(&"deep_freeze"), 5)
	assert_eq(s.digest(), s.clone().digest(), "clone has the same digest")
	assert_eq(s.digest().length(), 32, "md5 hex")
	var t := s.clone(); t.players[1].hero_hp -= 1
	assert_true(t.digest() != s.digest(), "hp change")
	t = s.clone(); t.rng.randi()
	assert_true(t.digest() != s.digest(), "rng advance")
	t = s.clone(); var c: CardData = t.players[0].hand.pop_back(); t.players[0].hand.push_front(c)
	assert_true(t.digest() != s.digest(), "hand order")
	return true

func test_builtin_decks_are_legal() -> bool:
	for id: StringName in CardDB.DECK_ORDER:
		assert_eq(DeckStore.validate(CardDB.deck(id).cards), "", "%s legal" % id)
	return true

func test_deck_codec_round_trip_and_rejects() -> bool:
	var d := CardDB.deck(&"sugar_storm")
	var enc := DeckCodec.encode(d)
	assert_eq(DeckCodec.check(enc), "", "encoded deck passes")
	var back := DeckCodec.decode(enc, &"online_1")
	assert_eq(_ids(back.cards), _ids(d.cards), "same cards in order")
	assert_eq(back.lands, d.lands, "same lands")
	var short := enc.duplicate(true); (short["cards"] as Array).pop_back()
	assert_true(DeckCodec.check(short) != "", "29 cards refused")
	var bad := enc.duplicate(true); bad["cards"][0] = "no_such_card"
	assert_true(DeckCodec.check(bad) != "", "unknown id refused")
	assert_true(DeckCodec.check({"name": 3}) != "", "bad shape refused")
	assert_true(DeckCodec.check("x") != "", "not a dictionary refused")
	return true
```
(`_ids(arr)` is a helper in the same file mapping cards to ids.)

- [ ] **Step 2: Run, expect failures** — `--only=test_net_core` → FAIL (`digest`/`DeckCodec` not found).
- [ ] **Step 3: Implement** `setup(..., first)`, `digest()` (build one canonical `Array` of values, `var_to_str`
  it, `.md5_text()`), and `DeckCodec`. If a built-in deck fails `test_builtin_decks_are_legal`, stop and record it
  in the ledger — do not loosen `DeckStore.validate`.
- [ ] **Step 4: Run** `--only=test_net_core` → all pass; then the full suite → 0 failed.
- [ ] **Step 5: Commit** `feat: engine hooks for online play (setup first, digest, deck codec)`.

### Task 2: Version — card fingerprint and rules stamp

**Files:**
- Create: `core/net_version.gd`, `core/rules_stamp.gd` (generated), `tools/stamp_rules.gd`
- Test: `tests/test_net_version.gd`

**Interfaces:**
- Produces: `NetVersion.current() -> String` = `"n1-" + md5(cards_fingerprint() + RulesStamp.HASH).substr(0, 10)`.
- Produces: `NetVersion.cards_fingerprint() -> String` — md5 over `CardDB.all_cards()` sorted by id; each card
  dumped as every property with `PROPERTY_USAGE_STORAGE`, recursing into `Resource` values (effects) and arrays.
- Produces: `NetVersion.rules_source_hash() -> String` — md5 of the text of every `res://core/*.gd` except
  `rules_stamp.gd`, files sorted by name. `RulesStamp.HASH: String` const.
- Produces: `tools/stamp_rules.gd` (`extends SceneTree`) rewrites `core/rules_stamp.gd` with the current hash and
  prints it.

- [ ] **Step 1: Failing tests**

```gdscript
func test_rules_stamp_is_current() -> bool:
	assert_eq(RulesStamp.HASH, NetVersion.rules_source_hash(), "run tools/stamp_rules.gd after changing core/")
	return true

func test_version_format_and_card_sensitivity() -> bool:
	var v := NetVersion.current()
	assert_true(v.begins_with("n1-") and v.length() == 13, "format n1-xxxxxxxxxx")
	assert_eq(NetVersion.current(), v, "stable")
	var c := CardDB.card(&"mossback"); var old: int = c.attack
	c.attack += 1
	assert_true(NetVersion.current() != v, "a stat change changes the version")
	c.attack = old
	assert_eq(NetVersion.current(), v, "back to the same version")
	return true
```
- [ ] **Step 2: Run** `--only=test_net_version` → FAIL.
- [ ] **Step 3: Implement** the three files, then run `godot --headless --path . --script res://tools/stamp_rules.gd`.
  Cache nothing in `NetVersion` (cards can change in tests).
- [ ] **Step 4: Run** `--only=test_net_version` → pass; full suite → 0 failed.
- [ ] **Step 5: Commit** `feat: online version string from card data and a rules stamp`.

### Task 3: Seat mirror

**Files:**
- Create: `core/seat_view.gd`
- Test: `tests/test_seat_view.gd`

**Interfaces:**
- Produces: `class_name SeatView`, `SeatView.new(real: GameState, seat: int)`; fields `real`, `view`, `seat`.
  Seat 0 → `view == real` (same object) and every method is the identity.
- `sync() -> void` — copy flipped scalars real → view (spec 3.3); call after every apply.
- `flip(p: int) -> int` — `1 - p` for seat 1 when `p` is 0/1; identity otherwise.
- `events_to_view(ev: Array[GameEvent]) -> Array[GameEvent]` — seat 1: new `GameEvent`s with `"player"` and
  `"winner"` flipped (data deep-copied); seat 0: the same array.
- `action_to_real(a: Action) -> Action` / `action_to_view(a: Action) -> Action` — copies with `player` and each
  target's `"player"` flipped.

- [ ] **Step 1: Failing tests**

```gdscript
func test_mirror_tracks_a_whole_match() -> bool:
	var real := Rules.setup(CardDB.deck(&"grove_guard"), CardDB.deck(&"blaze_rush"), 31)
	var sv := SeatView.new(real, 1)
	var ais: Array[AIPlayer] = [AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 3), AIPlayer.new(1, AIPlayer.Difficulty.MEDIUM, 4)]
	var ev := Rules.start_turn(real); sv.sync()
	_check_events(ev, sv.events_to_view(ev))
	var steps := 0
	while real.phase != GameState.Phase.OVER and steps < 3000:
		var a: Action = ais[real.active].choose_action(real) if real.phase == GameState.Phase.MAIN \
			else Action.choose(real.pending_player, 0)
		var va := sv.action_to_view(a)
		assert_eq(Rules.validate(sv.view, va), Rules.validate(real, a), "same verdict on the mirror")
		ev = Rules.apply(real, a); sv.sync(); steps += 1
		_check_events(ev, sv.events_to_view(ev))
		_check_mirror(real, sv.view)
	assert_eq(real.phase, GameState.Phase.OVER, "match ended")
	assert_eq(sv.view.winner, 1 - real.winner, "winner flipped")
	return true

func test_seat_zero_is_identity() -> bool:
	var real := Rules.setup(CardDB.deck(&"grove_guard"), CardDB.deck(&"blaze_rush"), 2)
	var sv := SeatView.new(real, 0)
	assert_true(sv.view == real, "same object")
	var a := Action.play(0, 1, 2, [{"player": 1, "lane": 3}])
	assert_eq(sv.action_to_real(a).to_dict(), a.to_dict(), "action unchanged")
	return true

func test_action_flip_round_trip() -> bool:
	var sv := SeatView.new(Fx.blank(), 1)
	var a := Action.play(0, 1, 2, [{"player": 1, "lane": 3}, {"discard": 4}])
	var r := sv.action_to_real(a)
	assert_eq([r.player, r.targets[0]["player"], r.targets[1].has("player")], [1, 0, false], "flipped")
	assert_eq(sv.action_to_view(r).to_dict(), a.to_dict(), "round trip")
	return true
```
`_check_mirror` asserts `view.players[i] == real.players[1 - i]` (identity) and the five flipped scalars plus
`turn`/`phase`; `_check_events` asserts same length/types and flipped `player`/`winner`.
- [ ] **Step 2: Run** `--only=test_seat_view` → FAIL.
- [ ] **Step 3: Implement** `core/seat_view.gd`; re-stamp rules.
- [ ] **Step 4: Run** `--only=test_seat_view` → pass; full suite → 0 failed.
- [ ] **Step 5: Commit** `feat: seat mirror so either seat sees itself as player 0`.

### Task 4: Rival drivers — move the AI out of `match.gd`

**Files:**
- Create: `view/rivals/rival_driver.gd`, `view/rivals/ai_rival.gd`
- Modify: `view/match.gd` (fields `ai`/`difficulty` → `driver`, `seats`; `perform`, `_on_action_requested`,
  `_human_dream_up`, `_on_end_turn_pressed`, `request_attack`, `_ai_turn`, `_begin`, `refresh_ui`)
- Modify: `tests/test_effects_playback.gd:156` (`m._ai_turn()` → `(m.driver as AiRival).rival_turn()`)
- Test: `tests/test_rival_driver.gd`

**Interfaces:**
- Consumes: `SeatView` (Task 3).
- Produces: `class_name RivalDriver extends RefCounted` with `var m: MatchController` and overridable async
  methods: `begin() -> void` (after the opening played), `submit(a: Action) -> void` (local view-space action,
  returns after it has played), `attack(lane: int, target_lane: int, hit: Action.Hit) -> void`,
  `blocks_input() -> bool` (default false), `process(delta: float) -> void`, `menu_changed(open: bool) -> void`,
  `leave() -> void`, `rival_name() -> String` (default "Rival"), `is_online() -> bool` (default false).
- Produces: `class_name AiRival extends RivalDriver`; `AiRival.new(ai: AIPlayer)`; `rival_turn() -> void` (today's
  `_ai_turn`).
- Produces on `MatchController`: `var seats: SeatView`, `var driver: RivalDriver`, `state` = `seats.view`;
  `apply_local(a: Action) -> Array[GameEvent]` (apply a view-space action on `seats.real`, `sync`, return view-space
  events); `play_events(ev: Array[GameEvent]) -> void` (playback + results when over — the old tail of
  `perform`); `perform(a)` keeps its signature (validate on view, `apply_local`, `play_events`).
  `can_act` in `refresh_ui` also requires `not driver.blocks_input()`.

- [ ] **Step 1: Failing test** `test_match_uses_ai_driver`: load a match with `Fx.load_match()`; assert
  `m.driver is AiRival`, `m.seats.seat == 0`, `m.state == m.seats.real`, `m.driver.rival_name() == "Rival"`.
- [ ] **Step 2: Run** `--only=test_rival_driver` → FAIL.
- [ ] **Step 3: Implement.** Pure move of behaviour: AI turn loop, AI block roll for human attacks, END TURN
  followed by the AI turn — all inside `AiRival`. No behaviour change.
- [ ] **Step 4: Run** `--only=test_rival_driver`, `--only=test_full_match`, `--only=test_effects_playback` → pass;
  full suite → 0 failed.
- [ ] **Step 5: Commit** `refactor: rival drivers; the AI turn moves into AiRival`.

### Task 5: Menu button works at any time (+ Esc; vs AI it pauses)

**Files:**
- Modify: `view/ui/hud.gd:279-282` (`set_input_enabled` no longer touches `pause_button`), `_build_pause`, add Esc
- Modify: `view/rivals/ai_rival.gd` (wait while paused), `view/match.gd:367`
- Test: `tests/test_menu_anytime.gd`

**Interfaces:**
- Produces on `Hud`: `toggle_pause() -> void`; Esc (`ui_cancel`) toggles the menu when no other overlay
  (results, discard viewer) is open; opening calls `menu_changed(true)` on the driver through `pause_changed`.
- Produces on `AiRival`: before each AI move, `while m.hud.is_paused(): await process_frame`.

- [ ] **Step 1: Failing tests**
  - `test_menu_enabled_on_rival_turn`: load a match, force the rival's turn
    (`m.perform(Action.end_turn(MatchController.HUMAN))` without awaiting the AI); assert
    `not m.hud.pause_button.disabled` while `m.state.active == MatchController.AI`.
  - `test_ai_waits_while_menu_open`: open the menu, start `rival_turn()`, wait 120 frames; assert the AI made no
    move (rival hand size, board and `state.active` unchanged); close the menu; wait until the turn passes back;
    assert `state.active == HUMAN`.
  - `test_escape_toggles_menu`: send an `InputEventKey` Esc → `is_paused()`; again → not paused.
- [ ] **Step 2: Run** `--only=test_menu_anytime` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** → pass; full suite → 0 failed.
- [ ] **Step 5: Commit** `fix: the menu opens on the rival's turn too; vs AI it really pauses`.

**Checkpoint 1:** screenshot of the menu open during the AI's turn (`tools/` screenshot flow used in earlier
stages); note in the ledger. No user wait (autonomy rule).

## Stage 2 — Server (`server/`)

### Task 6: Server scaffold, protocol, codes, router `/health`

**Files:**
- Create: `server/package.json`, `server/wrangler.jsonc`, `server/tsconfig.json`, `server/vitest.config.ts`,
  `server/.gdignore` (empty), `server/src/index.ts`, `server/src/protocol.ts`, `server/src/codes.ts`,
  `server/test/codes.test.ts`, `server/test/protocol.test.ts`, `server/test/router.test.ts`
- Modify: `.gitignore` (add `server/node_modules/`, `server/.wrangler/`)

**Interfaces:**
- `wrangler.jsonc`: `name: "dream-isles-online"`, `main: "src/index.ts"`, the newest `compatibility_date` the
  installed wrangler accepts, `durable_objects.bindings` `ROOM` → `Room`, `LOBBY` → `Lobby`, `migrations:
  [{tag: "v1", new_sqlite_classes: ["Room", "Lobby"]}]`.
- `codes.ts`: `WORDS: string[]` (≥ 120 friendly 3–5 letter words, uppercase, reviewed for rude combos),
  `makeCode(rand: () => number): string`, `isCode(s: string): boolean`.
- `protocol.ts`: `LIMITS = {maxBytes: 4096, perSecond: 20, nameMax: 16, deckNameMax: 24, deckSize: 30}`,
  `TIMES = {blockMs: 10_000, backstopMs: 70_000, reconnectMs: 60_000, claimedMs: 120_000, overMs: 600_000,
  emptyMs: 600_000}`, `ActionType = {PLAY_CARD:0, BOOP:1, ATTACK:2, CHOOSE:3, END_TURN:4}`, client/server message
  types (spec 4.1/4.2), `parseClient(raw: string): ClientMsg | null` (rejects oversize, non-JSON, unknown `t`,
  wrong field types), `cleanName(s: unknown): string`, `checkDeckShape(d: unknown): boolean`,
  `actionDict(partial): ActionDict` (fills `Action.to_dict` defaults).
- `index.ts`: `GET /health` → 200 `ok`; unknown path → 404. (Room/Lobby routes come in Tasks 7 and 10; export
  stub `Room`/`Lobby` classes now so wrangler builds.)

- [ ] **Step 1:** `cd server && npm init -y` then `npm i -D wrangler typescript vitest @cloudflare/vitest-pool-workers @cloudflare/workers-types`
  (if the pool rejects the vitest version, pin vitest to the version the pool's peer range names).
- [ ] **Step 2: Failing tests**

```ts
// codes.test.ts
it("makes valid codes", () => { for (let i = 0; i < 500; i++) expect(isCode(makeCode(Math.random))).toBe(true); });
it("rejects bad codes", () => { for (const c of ["FROG42", "frog-42", "FR-42", "FROGGY-42", "FROG-4", ""]) expect(isCode(c)).toBe(false); });
// protocol.test.ts
it("cleans names", () => {
  expect(cleanName("  Bo\u0007b  ")).toBe("Bob");
  expect(cleanName("x".repeat(40))).toHaveLength(16);
  expect(cleanName("")).toBe("Dreamer");
  expect(cleanName(42)).toBe("Dreamer");
});
it("parses only known, well-typed, small messages", () => {
  expect(parseClient('{"t":"block","blocked":true}')).toEqual({ t: "block", blocked: true });
  expect(parseClient('{"t":"block","blocked":"yes"}')).toBeNull();
  expect(parseClient('{"t":"nope"}')).toBeNull();
  expect(parseClient("not json")).toBeNull();
  expect(parseClient(JSON.stringify({ t: "hash", seq: 1, d: "x".repeat(5000) }))).toBeNull();
});
it("checks deck shape", () => {
  const ok = { name: "Mine", lands: [0, 0, 1, 0], cards: Array(30).fill("mossback") };
  expect(checkDeckShape(ok)).toBe(true);
  expect(checkDeckShape({ ...ok, cards: ok.cards.slice(1) })).toBe(false);
  expect(checkDeckShape({ ...ok, lands: [0, 0, 9, 0] })).toBe(false);
});
// router.test.ts (pool-workers SELF)
it("answers /health", async () => { const r = await SELF.fetch("http://x/health"); expect(await r.text()).toBe("ok"); });
it("404s unknown paths", async () => { expect((await SELF.fetch("http://x/nope")).status).toBe(404); });
```
- [ ] **Step 3: Run** `npx vitest run` → FAIL. **Step 4: Implement.** **Step 5: Run** → pass;
  `npx wrangler deploy --dry-run` → builds.
- [ ] **Step 6: Commit** `feat(server): worker scaffold, protocol limits, room codes`.

### Task 7: Referee — seats, start, moves, rejection

**Files:**
- Create: `server/src/referee.ts`, `server/test/referee.test.ts`

**Interfaces:**
- `type Seat = 0 | 1`; `type Out = { to: Seat; msg: ServerMsg }` (send to "both" = two `Out`s).
- `RoomState` (JSON-serializable): `code, quick, status: "claimed"|"waiting"|"playing"|"over", version,
  seats: [SeatInfo|null, SeatInfo|null]` (`{name, deck, token}`), `connected: [bool, bool]`, `seed, first, active,
  log: ActionDict[], pending: {seat, lane, target, hit} | null, hashes: Record<number, [string|null, string|null]>,
  results: [number|null, number|null], rematch: [bool, bool], over: {winner, reason}|null, matchNo,
  lastActiveAt, blockDeadline, reconnectDeadline: [number|null, number|null], cleanupAt`.
- `class Referee { constructor(s: RoomState, rand: () => number); static fresh(code: string, quick: boolean,
  now: number): RoomState; hello(role: "host"|"join", msg: HelloMsg, now: number): { seat: Seat | null; out: Out[];
  close?: boolean }; message(seat: Seat, msg: ClientMsg, now: number): Out[]; disconnect(seat: Seat, now: number):
  Out[]; tick(now: number): Out[]; nextDeadline(): number | null; dead(now: number): boolean }`.
- Hello rules (spec 4.3/4.5): token → that seat (rejoin; `start` with full `log`); host + `claimed` → seat 0 +
  `waiting`; join + `claimed` && quick → seat 0 + `waiting`; join + `waiting` → version must equal → seat 1 →
  `start` to both (`seed` = 31-bit from `rand`, `first` 0/1); otherwise `error` (`no_room` when state is null —
  handled by the DO, `full`, `over`, `version`, `bad_token`, `bad_hello`) with `close: true`.
- `act` from the active seat with type ≠ ATTACK → `player` forced to the seat → log, `move {seq, a}` to both;
  END_TURN flips `active`. From the other seat, while an attack is pending, or when not `playing` →
  `rejected {why}` to the sender only.

- [ ] **Step 1: Failing tests** (helper `room()` = fresh referee with a seeded `rand`; `hello(name)` builds a valid
  hello with version `"n1-test"`):
  - `host then join starts with the same seed/first/names/decks for both seats`.
  - `join with another version → error version, close`.
  - `third joiner → error full`; `wrong token → error bad_token`; `bad deck shape → error bad_hello`.
  - `moves are numbered from 1 and sent to both; END_TURN flips active`.
  - `act from the waiting seat → rejected to sender only, no move`.
  - `act claiming ATTACK type → rejected` (attacks must use `attack`).
  - `rejoin with token gets start with the full log and seat`.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** → pass.
- [ ] **Step 5: Commit** `feat(server): referee seats, start and move numbering`.

### Task 8: Referee — attack/block handshake and timers

**Files:** Modify `server/src/referee.ts`; Test `server/test/referee_timers.test.ts`

**Interfaces:** `attack {lane, target, hit}`: target −1 → ATTACK move at once (`blocked: false`); else
`pending` set, `block_wanted {lane, target, hit}` to the defender, `blocking` to the attacker, `blockDeadline =
now + 10 s`. `block {blocked}` from the defender completes the move. `tick(now)`: block deadline → `blocked:
false`; backstop: `playing`, no pending, `now − lastActiveAt ≥ 70 s` → `move {seq, a: END_TURN for active, auto:
true}`; `lastActiveAt` refreshes on any message from the active seat and when a pending attack completes.

- [ ] **Step 1: Failing tests**
  - `hero attack is numbered at once with blocked false`.
  - `creature attack: defender gets block_wanted, attacker blocking, block completes the move with hit+blocked`.
  - `block from the attacker is ignored`; `a second attack while pending is rejected`.
  - `no block within 10 s → move with blocked false`.
  - `70 s silence from the active seat → auto END_TURN move; 69 s → nothing`; `no backstop while an attack is
    pending`.
  - **Review Focus 1:** `backstop END_TURN, then the late act from the same seat → rejected, log unchanged`.
  - **Review Focus 2:** `defender rejoins while pending → start then block_wanted`; `attacker rejoins while pending →
    start then blocking`.
  - `nextDeadline is the earliest of block, backstop, reconnect, cleanup`.
- [ ] **Step 2–4:** run → FAIL, implement, run → pass.
- [ ] **Step 5: Commit** `feat(server): block handshake, block timeout and turn backstop`.

### Task 9: Referee — endings, rematch, disconnects, cleanup

**Files:** Modify `server/src/referee.ts`; Test `server/test/referee_end.test.ts`

**Interfaces:** `hash {seq, d}`: both present and different → `over {winner: -1, reason: "desync"}`; keep only the
last 8 seqs. `desync` → same. `result {winner}` from both: equal → `over normal`, different → desync. `concede` →
`over concede` (rival wins). `rematch`: only in `over`, reason ≠ desync, both connected; both sent → new seed and
first, empty log, `matchNo + 1`, `start` to both. `disconnect`: `playing` → `opponent away until` to the other,
`reconnectDeadline = now + 60 s`; `over` → `opponent left` to the other; nobody connected → `cleanupAt = now +
10 min`. Rejoin in time → `opponent back`. `tick`: reconnect deadline → `over forfeit` (present seat wins).
`dead(now)`: `cleanupAt` passed (`claimed` → created + 2 min; `over` → over-time + 10 min).

- [ ] **Step 1: Failing tests**
  - `different hashes for the same seq → over desync to both`; `equal hashes → nothing`.
  - `matching results → over normal; different results → desync`.
  - `concede → over concede, rival is winner`.
  - `rematch from both after a normal end → new start with matchNo 1, new seed, empty log`.
  - **Review Focus 5:** `rematch after desync → rejected`; `rematch after the rival left → rejected with why
    "left"`.
  - `drop during play → opponent away with until = now + 60 s; rejoin → opponent back; 60 s → over forfeit`.
  - `claimed room unused for 2 min → dead`; `over room → dead after 10 min`.
- [ ] **Step 2–4:** run → FAIL, implement, run → pass.
- [ ] **Step 5: Commit** `feat(server): endings, rematch, reconnect window and cleanup`.

### Task 10: Durable Objects and routes — Room, Lobby, `/host`, `/join/<code>`, `/queue`

**Files:**
- Create: `server/src/room.ts`, `server/src/lobby.ts`, `server/test/room.test.ts`, `server/test/lobby.test.ts`
- Modify: `server/src/index.ts`

**Interfaces:**
- `Room extends DurableObject`: RPC `claim(code: string, quick: boolean): Promise<boolean>` (false if state
  exists); `fetch` accepts the WS upgrade (`ctx.acceptWebSocket`), stores `{role, seat|null}` with
  `ws.serializeAttachment`; `webSocketMessage` → size/rate guard (close 1008) → `parseClient` → `hello` or
  `referee.message` → send `Out`s to the sockets by seat → persist `RoomState` under key `room` (skip for `hash`)
  → `setAlarm(nextDeadline)`; `webSocketClose` → `referee.disconnect`; `alarm` → `referee.tick`, then
  `deleteAll()` when `dead`. Unknown room (no state, not claimed) → `error no_room` + close.
- `Lobby extends DurableObject`: WS upgrade with `?v=<version>` → `acceptWebSocket(ws, [v])`; when another open
  socket has the same tag, claim a code on a Room (`quick = true`, retry on collision), send `{t:"matched", code}`
  to both, close both.
- Router: `/host` → claim loop then forward with `role=host&code=`; `/join/<code>` → 400 unless `isCode`, forward
  with `role=join&code=`; `/queue?v=` → Lobby named `lobby`. Non-upgrade requests to these → 426.

- [ ] **Step 1: Failing tests** (pool-workers, real WebSockets via `SELF.fetch` with `Upgrade: websocket`):
  - `host gets welcome+waiting with a code; join by that code starts both`.
  - `join to an unknown code → error no_room`.
  - `two queue sockets with the same version both get matched with the same code; different versions do not`.
  - `oversize message closes the socket`; `21 messages in one second closes the socket`.
  - `state survives: after a move, a rejoining socket with the token gets the log`.
- [ ] **Step 2–4:** run → FAIL, implement, run → pass. `npx wrangler deploy --dry-run` builds.
- [ ] **Step 5: Commit** `feat(server): room and lobby durable objects with host/join/queue routes`.

## Stage 3 — Godot online

### Task 11: Transport, session, fake relay

**Files:**
- Create: `net/ws_transport.gd`, `net/online_session.gd`, `net/fake_relay.gd`, `net/bot_brain.gd`
- Test: `tests/test_online_session.gd`

**Interfaces:**
- `class_name WsTransport extends RefCounted`: signals `opened`, `received(msg: Dictionary)`,
  `closed(code: int, reason: String)`; `open(url: String)`, `send(msg: Dictionary)` (queued until open),
  `poll()` (call every frame), `close()`, `is_open() -> bool`.
- `class_name FakeRelay extends RefCounted`: `transport(role: StringName = &"join") -> FakeRelay.Link` (a `Link`
  has the same signals and `send`/`close`/`is_open` as `WsTransport`; the first link of a room is opened with
  `&"host"`); `pump()` delivers queued messages in order; `block_timeout()`, `backstop()`, `drop(seat: int)`
  (closes that seat's link as if the network died); `var seed: int`. Rejoin = a new `transport()` link plus an
  `OnlineSession` built with the saved token. Mirrors the referee's rules for
  hello/start/act/attack/block/hash/result/desync/concede/rematch (no wall-clock timers, no lobby).
- `class_name OnlineSession extends RefCounted`: signals `changed`, `started(rejoined: bool)`;
  `OnlineSession.new(link: Object, name: String, deck: DeckData, version: String, token := "")`;
  `hello()`, `on_message(msg: Dictionary)`; fields `seat`, `token`, `code`, `names`, `decks`, `seed`, `first`,
  `match_no`, `state: GameState`, `applied: int`, `inbox: Array[Dictionary]`, `status: StringName`
  (`&"connecting" | &"waiting" | &"playing" | &"over" | &"error"`), `error_code`, `error_msg`, `over: Dictionary`,
  `rival_away_until: int`, `rival_left: bool`, `rival_wants_rematch: bool`, `moves: Array[Dictionary]`.
  `take_opening() -> Array[GameEvent]` (once per `start`, empty after a log replay); `next() -> Dictionary`;
  `apply_move(msg: Dictionary) -> Array[GameEvent]` (validate → apply → `hash` → `result` when over; invalid →
  `desync` + `user://desync_<code>.json` + returns `[]`); `send_act(a: Action)`, `send_attack(lane: int, target:
  int, hit: int)`, `send_block(blocked: bool)`, `concede()`, `request_rematch()`; `is_my_turn() -> bool`.
  Inbox holds `move`, `block_wanted`, `blocking`, `rejected`, `opponent`, `rematch_wanted`, `over`.
- `class_name BotBrain extends RefCounted`: `BotBrain.new(seed: int)`; `step(s: OnlineSession) -> void` — drains
  the inbox (applies moves, answers `block_wanted` with a seeded roll) and, on its turn with nothing in flight,
  sends the AI's next action (ATTACK → `send_attack` with `roll_hit()`).

- [ ] **Step 1: Failing tests**
  - `test_fifty_online_matches_stay_in_sync`: for i in 50: `FakeRelay` seed i; two sessions (decks: built-in
    rotation, every 5th a custom deck made with `DeckStore.make` from shuffled collectible cards that passes
    `validate`) driven by `BotBrain`; pump until both `over`; assert equal `state.digest()` after every applied
    seq (collect per seq), same winner, `over.reason == "normal"`.
  - `test_rejoin_replays_to_same_digest`: play 40 moves, `drop(1)`, a new session on a new link with seat 1's token; assert its
    digest equals seat 0's and `take_opening()` is empty; finish the match in sync.
  - **Review Focus 1:** `test_backstop_crossing_own_act`: on seat 0's turn call `relay.backstop()` then
    `send_act` (play a card) before pumping; assert seat 0 sees an `auto` END_TURN move and a `rejected`; digests
    stay equal.
  - `test_invalid_move_is_desync`: inject a `move` the engine refuses into seat 1; assert seat 1 sent `desync` and
    the relay answered `over` with reason `desync`; `user://desync_<code>.json` exists.
  - `test_rival_deck_illegal_is_desync`: relay `start` carrying a 29-card deck → `desync`.
  - `test_concede_and_rematch`.
- [ ] **Step 2–4:** run `--only=test_online_session` → FAIL, implement, run → pass. Full suite 0 failed.
- [ ] **Step 5: Commit** `feat: online session protocol with a fake relay for tests`.

### Task 12: `Online` autoload — connect flows, rejoin file, reconnect

**Files:**
- Create: `autoload/online.gd`; Modify: `project.godot` (`Online="*res://autoload/online.gd"`),
  `autoload/settings.gd` (`player_name`, saved in `settings.cfg`, default `Dreamer` + 3 digits on first load)
- Test: `tests/test_online_autoload.gd`

**Interfaces:**
- `const SERVER_URL := "ws://127.0.0.1:8787"` (replaced at deploy, Task 16); `var server_url` (`--server=`
  overrides); `signal changed`, `signal match_ready`.
- `var session: OnlineSession`, `var state: StringName` (`&"idle" | &"searching" | &"hosting" | &"joining" |
  &"playing" | &"reconnecting" | &"error"`), `var message: String` (player-facing error/status).
- `quick_match(name: String, deck: DeckData)`, `host(name, deck)`, `join(code_text: String, name, deck)`,
  `rejoin()`, `cancel()`, `leave()` (concede if playing, close, forget rejoin).
- `static func normalize_code(text: String) -> String` ("" when not a code); `has_rejoin() -> bool`,
  `forget_rejoin()`; rejoin file `user://online_rejoin.json` `{code, token, version}` written on `welcome`,
  deleted on `over`.
- `link_factory: Callable` (tests inject `FakeRelay` links; default makes a `WsTransport` for a path).
- Reconnect: unexpected close while `playing` → `reconnecting`, retries after 1, 2, 4, 8, 16 s … until 60 s
  after the drop → then `error` "Lost the connection".
- A link that closes before it ever opened (any state but `playing`) → `error`, message "Can't reach the Dream Isles
  server".

- [ ] **Step 1: Failing tests**
  - **Review Focus 3:** `test_normalize_code`: `"frog42"`, `"FROG 42"`, `" frog-42 "` → `"FROG-42"`;
    `"frog"`, `"42"`, `"froggyy-42"`, `""` → `""`.
  - `test_player_name_default_and_saved`: fresh settings path → name matches `^Dreamer[1-9][0-9]{2}$`;
    set + save + reload → same.
  - `test_host_join_through_fake_relay`: two `Online`-like instances (instantiate the script twice with injected
    `link_factory`) host/join → both reach `playing`, `match_ready` emitted; rejoin file exists; `leave()` deletes
    it and the other side gets `over concede`.
  - `test_reconnect_after_drop`: drop the link mid-match → `reconnecting` → relay accepts the token → `playing`
    with the same digest.
  - `test_unreachable_server`: a link factory whose links close without opening → `state == &"error"`,
    `message == "Can't reach the Dream Isles server"`.
- [ ] **Step 2–4:** run → FAIL, implement, run → pass; full suite 0 failed.
- [ ] **Step 5: Commit** `feat: Online autoload with host/join/quick, rejoin and reconnect`.

### Task 13: `OnlineRival`, fuse, rival name, results, leave confirm

**Files:**
- Create: `view/rivals/online_rival.gd`, `view/ui/turn_fuse.gd`
- Modify: `view/match.gd` (`_ready` picks the driver: `Online.session` with status `playing` → `OnlineRival`;
  seed/decks/seats from the session; opening from `take_opening()`), `view/ui/hud.gd` (`set_online(rival_name:
  String)`, `set_fuse(seconds_left: float)`, `set_banner(text: String)`, leave confirm), `view/ui/results.gd`
  (`show_result(won: bool, turns: int, reason := "", title := "")`, `set_rematch(text: String, enabled: bool)`),
  `view/ui/timing_bar.gd` (`wait_block() -> void`: shows "Rival is blocking…" until `simulate_block`)
- Test: `tests/test_online_match.gd`

**Interfaces:**
- `OnlineRival.new(session: OnlineSession)`; implements `RivalDriver` (spec 5.2–5.5): `submit` sends and awaits
  the echo (a non-`auto` move by the local seat) or `rejected` (toast "Not now"); `attack` sends, calls
  `timing_bar.wait_block()` for creature targets, awaits the echo; `blocks_input()` true while a message is
  playing; `process(delta)` pumps the inbox one message at a time, runs the turn clock (`TURN_SECONDS := 50.0`,
  `FUSE_SECONDS := 15.0`), sets fuse and banners, ends the local turn at 0; `menu_changed` no pause;
  `leave()` → `Online.leave()`; `rival_name()` → the session's rival name. On session `started(rejoined)` while
  in a match → `get_tree().reload_current_scene()`.
- Results online: reasons "Rival conceded", "Rival left the match", "Out of sync — no winner" (title "NO
  CONTEST"); REMATCH → `session.request_rematch()` → "Waiting for rival…"; `rival_wants_rematch` → "Rival wants a
  rematch!"; `rival_left` or desync → button off with "Rival left" / "No rematch".
- Hud online: pause title "Menu", quit button "LEAVE MATCH" → confirm "Leaving gives your rival the win —
  leave?" (LEAVE / STAY) → `menu_requested`.

- [ ] **Step 1: Failing tests** (the match scene runs as **seat 1**; the remote seat 0 is a headless
  `OnlineSession` + `BotBrain` on the same `FakeRelay`; a helper node pumps the relay every frame; the local side
  is driven like `test_full_match` with `timing_bar.auto_stop`/`force_needle`):
  - `test_full_online_match_as_seat_one`: plays to the end; both digests equal; `m.view_resyncs == 0` (new
    counter `verify_views` increments whenever it resyncs a land or calls `sync_all`); results visible; rival
    corner shows the bot's name.
  - `test_banner_when_rival_drops`: `relay.drop(0)` mid-match → banner text starts with "Rival disconnected —
    waiting"; the remote rejoins → banner cleared.
  - `test_block_wanted_runs_live_block_bar`: a remote creature attack produces a `block` message from the local
    side and the move plays once.
  - `test_fuse_ends_turn`: set the clock to 0.5 s on the local turn → END_TURN sent within 60 frames; fuse
    visible below 15 s.
  - `test_leave_confirms_then_concedes`: menu → LEAVE MATCH shows the confirm; STAY keeps the match; LEAVE → remote
    gets `over concede`.
  - **Review Focus 5:** `test_rematch_off_after_rival_left`: remote closes after the end → REMATCH disabled with
    "Rival left".
- [ ] **Step 2–4:** run `--only=test_online_match` → FAIL, implement, run → pass; full suite 0 failed.
- [ ] **Step 5: Commit** `feat: online matches in the view — live blocks, fuse, rival name, rematch, leave`.

### Task 14: Main menu — PLAY vs AI / PLAY ONLINE, online panel, rejoin banner

**Files:**
- Create: `menus/online_panel.gd`; Modify: `menus/main_menu.gd` (`_build_ui`, `_play`, rejoin banner)
- Test: `tests/test_online_panel.gd`

**Interfaces:**
- `class_name OnlinePanel extends PanelContainer`; `signal closed`; `setup(deck: DeckData)`; states shown from
  `Online.state`/`Online.message` (spec 2.1 copy, verbatim); name `LineEdit` (max 16) saved to
  `Settings.player_name`; code `LineEdit` + JOIN; QUICK MATCH / HOST ROOM / CANCEL / COPY (`DisplayServer.
  clipboard_set`); on `Online.match_ready` the menu changes scene to `res://view/match.tscn`.
- Main menu: buttons `PLAY vs AI` (old `_play`) and `PLAY ONLINE` (opens the panel via `_open_panel`); when
  `Online.has_rejoin()` a banner "Rejoin your match?" with REJOIN / FORGET.

- [ ] **Step 1: Failing tests**
  - `test_menu_has_both_play_buttons`.
  - **Review Focus 4:** `test_illegal_custom_deck_blocked`: a custom deck with 29 cards selected → QUICK MATCH /
    HOST / JOIN show "That deck can't be used online: A deck needs 30 cards (29 now)" and `Online.state` stays
    `idle`.
  - `test_join_with_bad_code_shows_message`: "xyz" → "That isn't a room code" and no connection attempt.
  - `test_unreachable_server_shows_retry`: links that never open → "Can't reach the Dream Isles server" and a
    RETRY button that repeats the last request.
  - `test_hosting_shows_code` (fake relay link factory): HOST → the code label shows `FROG-42`-shaped text.
  - `test_rejoin_banner_when_file_exists`.
- [ ] **Step 2–4:** run → FAIL, implement, run → pass; full suite 0 failed.
- [ ] **Step 5: Commit** `feat: PLAY ONLINE panel with quick match, host, join and rejoin`.

### Task 15: Online bot and end-to-end run against `wrangler dev`

**Files:**
- Create: `tools/online_bot.gd`, `tools/e2e_online.sh`

**Interfaces:**
- `godot --headless --path . --script res://tools/online_bot.gd -- --server=ws://127.0.0.1:8787
  --mode=host|join=<CODE>|quick --deck=<id> --brain-seed=<n> --out=<file.json>`; host writes the code to
  `<out>.code` as soon as it has one; on `over` writes `{winner, reason, digest, turns, seat}` and quits 0; quits 1
  on error or after 600 s.
- `tools/e2e_online.sh`: starts `npx wrangler dev --port 8787` in `server/`, waits for `/health`, runs host+join
  bots and then two quick bots, asserts both outputs of each pair agree on `winner`, `reason == "normal"` and
  `digest`, stops wrangler, exits non-zero on any mismatch.

- [ ] **Step 1:** Implement the bot (uses `WsTransport`, `OnlineSession`, `BotBrain`).
- [ ] **Step 2: Run** `bash tools/e2e_online.sh` → `E2E OK` for both pairs.
- [ ] **Step 3: Manual check:** export Web to a scratch dir (`godot --headless --export-release "Web"
  <scratch>/index.html`), serve it locally, open it with Playwright against `--server` default
  `ws://127.0.0.1:8787` (temporary local build only) and host; join from a desktop window; play a few turns;
  screenshots of both screens, the fuse and a live block bar (**Checkpoint 2**).
- [ ] **Step 4: Commit** `test: online bot and end-to-end run against the local server`.

## Stage 4 — Go live

### Task 16: Deploy, point the game at it, final review

**Files:** Modify `autoload/online.gd` (`SERVER_URL`); ledger; memory (`distribution`)

- [ ] **Step 1:** Ask the user to run `! cd server && npx wrangler login` (one-time, opens the browser).
- [ ] **Step 2:** `cd server && npx wrangler deploy` → note the `https://dream-isles-online.<sub>.workers.dev` URL;
  `curl …/health` → `ok`.
- [ ] **Step 3:** Set `SERVER_URL` to the `wss://` URL; run the E2E bots against it (`--server=wss://…`) once.
- [ ] **Step 4:** Full Godot suite + `npx vitest run` → 0 failed. Whole-branch review (requesting-code-review) and
  fix findings.
- [ ] **Step 5: Commit** `feat: point online play at the deployed server`. Web export + push only when the user
  says so; offer the Windows exe rebuild.
