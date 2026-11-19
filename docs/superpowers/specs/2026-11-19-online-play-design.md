# Dream Isles — Online Play (design)

Date: 2026-11-19 · Branch: `feat/online` · Status: approved in chat (sections 1–5), spec self-approved at the user's
"u dont need my approval u can continue".

## 1. Goal

Two people play Dream Isles against each other over the internet, each on their own machine — mainly friends in
the browser build (dream-isles.vercel.app), plus anyone in a quick-match queue. Playing the AI stays exactly as it
is, apart from the always-on menu button (5.6).

**What the user decided**

| Topic | Decision |
|---|---|
| Finding a match | Private **room codes** (host / join) **and** a **quick-match queue** |
| Block timing bar | The **defender plays it live** when a creature is attacked |
| Turn timer | **50 s** per turn, fuse shows in the last 15 s, turn ends itself at 0 |
| Server | **Cloudflare relay** (Worker + Durable Objects), free plan |
| Menu | Usable at any time; online it is "Menu" with LEAVE MATCH (= concede) |

**Assumptions (stated in chat, not contested)**

- Matches are between friends or casual strangers: no accounts, no ranked ladder, no anti-cheat. Both games know
  the seed, so a player who digs into the code could see the rival's hand or fake a timing-bar result. Accepted;
  the protocol leaves room to move to an authoritative server later.
- The browser build is the main client. The desktop builds speak the same protocol (WebSockets), so a rebuilt
  Windows exe can play the browser.

**Out of scope:** emotes/chat, ranked, spectating, AI stand-in while queueing, accounts, Dream Up picker UI
(online keeps today's "first card is taken" rule — Rules 2.0 Task 15 owns the picker).

## 2. Player experience

### 2.1 Main menu

- PLAY becomes **PLAY vs AI**; a new **PLAY ONLINE** button opens the online panel:
  - **Name** field (remembered in settings; default `Dreamer` + 3 digits, max 16 characters).
  - The deck shown is the one selected in the menu (built-in or custom).
  - **QUICK MATCH** → "Searching… 0:12" + CANCEL.
  - **HOST ROOM** → big code (`FROG-42`) + COPY + "Send this to a friend" + CANCEL.
  - **JOIN ROOM** → code field + JOIN (accepts `frog42`, `FROG 42`, `frog-42`).
  - Errors appear in the panel: "Can't reach the Dream Isles server" (+ RETRY), "No room called FROG-42",
    "That room is full", "That match is over", "Your friend has a different version — both refresh",
    "That deck can't be used online: <reason>".
- If a saved online match may still be running, the menu shows a banner **"Rejoin your match?"** REJOIN / FORGET.

### 2.2 In the match

- Same table, room and rival figure. The rival's hero corner shows the **rival's name** (vs AI: "Rival" as now).
- **Turn timer:** 50 s per turn, counted only while nothing is animating, no block bar is up and no move is
  waiting for its echo. A fuse burns along the END TURN button in the last 15 s; at 0 the turn ends (input is
  cancelled, END TURN is sent). The waiting player sees the same fuse for the rival's turn (an estimate).
- **Rival's turn:** their plays animate exactly like the AI's do today (arrow, simulated attack bar, playback).
- **Blocking:** when the rival attacks one of your creatures you see their arrow and their attack-bar result, then
  **your block bar** runs. When you attack a creature, after your attack bar the bar shows "Rival is blocking…"
  until their result arrives, then plays it.
- **Waiting for an echo:** your own moves animate when the server echoes them (~50–150 ms); input stays locked
  until then.
- **Menu** (II button or Esc) — see 5.6.
- **Banners:** "Rival disconnected — waiting 0:58", "Reconnecting…".
- **Results:** win/lose as now plus a reason line for online endings ("Rival conceded", "Rival left the match",
  "Out of sync — no winner") and a **REMATCH** button ("Waiting for rival…" once pressed; starts when both press).

## 3. Architecture

```
 Player A's game                     Cloudflare                     Player B's game
 ┌───────────────┐ WebSocket  ┌──────────────────────┐ WebSocket ┌───────────────┐
 │ Online (auto)  │◄─────────►│ Worker router        │◄─────────►│ Online (auto)  │
 │ OnlineSession  │           │  ├ Lobby DO (queue)  │           │ OnlineSession  │
 │ Rules engine   │           │  └ Room DO per code  │           │ Rules engine   │
 └───────────────┘            └──────────────────────┘           └───────────────┘
```

Lockstep: both games run the same deterministic rules engine from the same seed and decks; only moves travel.
The room numbers every move so both games apply them in one order.

### 3.1 Server — `server/` (TypeScript, one Cloudflare Worker)

- **Worker router** (all game traffic is WebSocket):
  - `GET /health` → `ok`.
  - `GET /host` (WS) → picks a free room code (claims it on the Room DO by RPC, retrying on collision) and
    forwards the upgrade to that Room DO with `role=host`.
  - `GET /join/<CODE>` (WS) → forwards to the Room DO named `<CODE>` (`role=join`).
  - `GET /queue?v=<version>` (WS) → forwards to the single **Lobby DO**.
- **Lobby DO** (one, named `lobby`): sockets tagged with their version. When a second socket with the same version
  is waiting, it claims a new room code, sends both `{t:"matched", code}` and closes them. CANCEL = the client
  closes its socket. Uses the WebSocket Hibernation API, no storage.
- **Room DO** (one per code, SQLite-backed, Hibernation API; sockets tagged `s0`/`s1`): the rule-blind referee —
  seats, names, decks, tokens, seed, first player, whose turn, move numbering, the attack→block handshake, move
  log (persisted per move), checksum comparison, results, concede, rematch, and timers through the DO alarm
  (block timeout, turn backstop, reconnect window, cleanup).
- Free-plan friendly: SQLite DO classes (`new_sqlite_classes`), Hibernation so idle rooms cost nothing.

### 3.2 Godot — new and changed units

| Unit | Kind | Job |
|---|---|---|
| `core/rules.gd` | change | `setup(deck_a, deck_b, seed, first := -1)`: the first-player roll still happens (so the rng stream is unchanged) but `first >= 0` overrides it |
| `core/game_state.gd` | change | `digest() -> String`: md5 of a canonical dump of the whole state incl. rng state |
| `core/net_version.gd` | new | `NetVersion.string()` = `"n1-" + md5(card data + rules stamp)[0..10]`; the version both games must share |
| `core/rules_stamp.gd` | new, generated | `const HASH` = md5 of `core/*.gd` sources; `tools/stamp_rules.gd` rewrites it, a test fails when it is stale |
| `core/deck_codec.gd` | new | deck ⇄ `{name, lands, cards:[ids]}`; decoding validates (unknown id, `DeckStore.validate`) |
| `core/seat_view.gd` | new | the seat mirror (3.3) |
| `net/ws_transport.gd` | new | WebSocketPeer wrapper (connect URL, send/receive JSON, poll, closed signal) |
| `net/online_session.gd` | new | protocol state machine, owns the canonical `GameState`; testable with a fake transport |
| `net/fake_relay.gd` | new (tests/tools) | GDScript copy of the room's ordering rules for headless two-session tests |
| `autoload/online.gd` | new autoload `Online` | keeps the transport + session alive across the menu → match scene change; rejoin file |
| `view/rivals/ai_rival.gd` | new | today's AI turn loop + AI block roll, moved out of `match.gd` |
| `view/rivals/online_rival.gd` | new | sends local moves, pumps the session inbox, live block bar, turn fuse, banners |
| `view/match.gd` | change | `driver` instead of `ai`; `perform` split into apply + `play_events`; mode from `Online` |
| `view/ui/hud.gd` | change | menu button always on, Esc, online menu wording + LEAVE confirm, rival name, fuse |
| `view/ui/turn_fuse.gd` | new | the burning fuse drawn along END TURN |
| `view/ui/results.gd` | change | reason line + REMATCH (online only) |
| `menus/online_panel.gd` | new | the online panel (2.1) |
| `menus/main_menu.gd` | change | PLAY vs AI / PLAY ONLINE buttons, rejoin banner |
| `autoload/settings.gd` | change | `player_name` saved with the other settings |
| `tools/online_bot.gd` | new | headless client where the AI plays a real online match (E2E) |

### 3.3 Seat mirror (`SeatView`)

The view assumes "player 0 = me (near side)" in ~80 places. Instead of touching them, the engine stays canonical
(host = player 0) and a seat-1 player's screen gets a **mirrored view state**:

- `view.players = [real.players[1], real.players[0]]` — the **same** `PlayerState` objects, so lanes, creatures and
  cards the view holds stay identical objects.
- Scalars are copied flipped after every apply: `active`, `first_player`, `winner`, `pending_player`,
  `field_owner` (p → 1−p; −1 stays −1); `turn`, `phase`, `field`, `pending_choice` copied as is.
- Events from the canonical engine get their `"player"` and `"winner"` fields flipped (the only player-bearing
  keys across all 42 event types — checked 2026-11-19).
- Actions built by the view are flipped back before sending (`player`, each target's `"player"`).
- The view only ever runs read-only `Rules` queries (`validate`, `card_cost`, `can_attack`, `legal_actions`) on the
  mirror. The rules are symmetric under swapping the players (checked: no hard-coded player index except
  `_hero_down`/the double-death rule, which use both indices or `active`), so those answers are correct.
- Seat 0 and vs-AI use the identity view (`view == real`, nothing flipped): one code path.

## 4. Protocol

JSON text frames, one object each, field `t` = type. Max 4 KB; more than 20 messages/s from one socket → the
server closes it.

### 4.1 Client → room

| `t` | Fields | When |
|---|---|---|
| `hello` | `v` version, `name`, `deck` `{name, lands, cards}`, `token?` | first message on a room socket; with `token` = rejoin |
| `act` | `a` action dict (`Action.to_dict`, canonical) | PLAY_CARD, BOOP, CHOOSE, END_TURN from the active seat |
| `attack` | `lane`, `target`, `hit` | attack intent from the active seat |
| `block` | `blocked` | defender's answer to `block_wanted` |
| `hash` | `seq`, `d` | after applying move `seq` |
| `result` | `winner` (canonical) | the engine reached game over |
| `desync` | `seq`, `why` | a move failed `Rules.validate` or the rival's deck failed to decode |
| `concede` | — | LEAVE MATCH |
| `rematch` | — | REMATCH pressed |

### 4.2 Room → client

| `t` | Fields | Meaning |
|---|---|---|
| `welcome` | `seat`, `token`, `code` | seat taken; save token |
| `waiting` | `code` | host waits for a friend |
| `start` | `seed`, `first`, `names[2]`, `decks[2]`, `log[]`, `match` | (re)start; `log` holds every move so far (rejoin), `match` counts rematches |
| `move` | `seq`, `a`, `auto?` | the next move, to both players; `auto: true` when the room made it (backstop END_TURN) |
| `block_wanted` | `lane`, `target`, `hit` | to the defender only |
| `blocking` | — | to the attacker: waiting for the defender |
| `rejected` | `why` | the sender's move was dropped (not its turn, attack pending…) |
| `opponent` | `status` (`away`/`back`/`left`), `until?` (ms epoch) | rival's connection (`left`: gone after the match ended — REMATCH turns off) |
| `rematch_wanted` | — | the rival pressed REMATCH |
| `over` | `winner`, `reason` (`normal`/`concede`/`forfeit`/`desync`) | match ended |
| `error` | `code`, `msg` | `no_room`, `full`, `version`, `over`, `bad_token`, `bad_hello` — socket closes after |

Lobby: client → nothing (version is in the URL); lobby → `{t:"matched", code}` then close.

### 4.3 Flow

1. **Start.** Each game sends `hello`. Host gets `welcome` + `waiting`. When both seats are filled and versions
   match (different version → `error version` to the joiner), the room picks `seed` (31-bit) and `first` (0/1),
   stores them and sends `start` to both. Each game checked its own deck before connecting (panel error). It now
   decodes both decks; a rival deck that fails (only possible with a modified client) is handled like a desync
   (`desync` → `over desync`). Then it runs `Rules.setup(decks[0], decks[1], seed, first)` + `Rules.start_turn`
   and shows the match.
2. **Moves.** Only the active seat may send `act`/`attack`. The room appends the move to the log, numbers it
   (`seq` from 1) and broadcasts `move`. It flips its `active` seat on END_TURN. Both games apply moves strictly in
   `seq` order through `Rules.apply` after `Rules.validate`; a move that fails validation is a desync (the game
   sends `desync`, the room answers `over desync` to both).
3. **Attacks.** `attack` on the hero (`target = -1`) is numbered at once as an ATTACK move (`blocked = false`).
   `attack` on a creature: the room stores the pending attack, sends `block_wanted` to the defender and `blocking`
   to the attacker; the defender's `block` (or the 10 s block timeout → `false`) completes it into an ATTACK move
   with `hit` and `blocked`. While an attack is pending, other `act`/`attack` messages are `rejected`.
4. **Checksums.** After applying move `seq` each game sends `hash`. When the room has both hashes for a `seq` and
   they differ → `over desync`. Only the latest few are kept.
5. **Game over.** Each game sends `result`. Both agree → room is `over` (reason `normal`). They disagree → desync.
6. **Concede.** `concede` → `over` with the rival as winner (reason `concede`).
7. **Rematch.** Allowed in `over` state (any reason but desync). When both seats sent `rematch`: new seed, new first,
   log cleared, `match` + 1, `start` to both. Same seats, names and decks.

### 4.4 Timers (all in the Room DO alarm; the alarm is set to the earliest deadline)

- **Block timeout:** 10 s after `block_wanted` → `blocked = false`.
- **Turn backstop:** 70 s with no message from the active seat (while no attack is pending) → the room adds an
  END_TURN move for that seat. Covers frozen background tabs and dropped players. The 50 s turn clock itself runs
  in the active player's game.
- **Reconnect window:** a seat's socket closes during `playing` → the rival gets `opponent away` with `until` =
  now + 60 s. Rejoin before then → `opponent back`; otherwise `over forfeit` (the present player wins).
- **Cleanup:** claimed but never joined → 2 min; `over` → 10 min; nobody connected → 10 min. Cleanup deletes all
  storage.

### 4.5 Rejoin

The game saves `{code, token, version}` to `user://online_rejoin.json` on `welcome` and deletes it on `over`
(or FORGET). Rejoin = connect `/join/<code>` and `hello` with the token. The room answers `welcome` + `start` with
the full `log`; the game re-runs setup, applies every logged move without animation, rebuilds all views
(`sync_all`) and continues. If an attack is pending, the room sends the rejoiner `block_wanted` again (defender)
or `blocking` (attacker) right after `start`. Lost connection mid-match → "Reconnecting…" and automatic retries after 1, 2, 4, 8 … s
until the 60 s window is over; then the menu.

### 4.6 Version

`NetVersion.string()` hashes all card data (every stored property of every card, effects included) plus
`RulesStamp.HASH` (md5 of the `core/*.gd` source). The rules stamp is regenerated by `tools/stamp_rules.gd`; a test
compares it with the current sources so a forgotten re-stamp fails the suite. Quick match only pairs equal
versions; a room refuses a joiner with another version.

## 5. Godot flow details

### 5.1 Match modes

`MatchController` picks its driver in `_ready`: `Online.session` with a started match → `OnlineRival`, else
`AiRival`. The seed, decks and first player come from the session online, from `Session` otherwise.

### 5.2 Local actions

- Hand plays, boops, CHOOSE, END TURN → `driver.submit(a)` (view-space action).
  - AI: `perform(a)` as today (END TURN then runs the AI turn).
  - Online: flip → `act`; input stays locked (`busy`) until the echo is played or `rejected` arrives.
- Attacks → `request_attack` runs the attack bar as today, then `driver.attack(lane, target, hit)`.
  - AI: roll block, simulate it, perform (today's code).
  - Online: send `attack`; if a creature is the target the bar shows "Rival is blocking…" until the ATTACK move
    arrives, then `simulate_block(blocked)` and the move plays.

### 5.3 The online pump

`OnlineRival` handles the session inbox one message at a time, awaiting each one's animations:

- `move`: apply on the canonical state (`session.apply_move`), flip events to view space, `play_events`; the
  session sends `hash`, and `result` when over. Before applying an ATTACK move:
  - the rival's attack on your **hero**: arrow + simulated attack bar (no block);
  - the rival's attack on a **creature**: nothing more (it was shown on `block_wanted`);
  - your attack on a **creature**: `simulate_block(blocked)` ends the "Rival is blocking…" bar;
  - your attack on the hero: nothing more.
- `block_wanted`: close the menu if open, arrow, simulated attack bar, live `run_block()`, send `block`.
- `opponent`, `rematch_wanted`, `over`: banners / results.

### 5.4 Turn fuse

Online only. `OnlineRival` keeps `turn_left` (50 s), reset when a turn starts (a `turn_started` event), counting
down only while nothing is busy. When `state.active` is the local player and it reaches 0: cancel input, close drag,
send END_TURN. The HUD shows the fuse when ≤ 15 s for either side.

### 5.5 Leaving

LEAVE MATCH → confirm "Leaving gives your rival the win — leave?" → `concede`, close the socket, delete the rejoin
file, back to the menu. Results → MENU also closes the socket.

### 5.6 Menu button (both modes)

- The II button and Esc work at all times (not only on your turn).
- vs AI it really pauses: the AI waits before each next move while the menu is open.
- Online it does not pause: title "Menu", QUIT TO MENU reads LEAVE MATCH (5.5); a `block_wanted` closes it.

## 6. Errors

| Case | Handling |
|---|---|
| Server unreachable | panel error + RETRY; vs AI unaffected |
| Code not found / full / over | `error` → panel message |
| Version differs | room: `error version`; queue: never paired |
| Own deck illegal | panel message before connecting |
| Rival deck illegal | treated as a desync (modified client only) |
| Own connection lost | "Reconnecting…" + retries with the token (4.5) |
| Rival disconnects | banner with countdown; forfeit win after 60 s |
| Desync / invalid move | "Out of sync — no winner"; `user://desync_<code>.json` (seed, first, decks, log, local digests) for a headless replay |
| Flood / oversize | server closes that socket |

## 7. Testing

- **Godot headless (existing runner):**
  - `Rules.setup` with `first` keeps the shuffles identical; `digest` stable and change-sensitive;
    `NetVersion` changes when a card stat changes; rules stamp up to date; deck codec round-trips built-in and
    custom decks and rejects bad ones; every built-in deck passes `DeckStore.validate`.
  - `SeatView`: full AI-vs-AI matches seen from seat 1 — the mirror equals the swapped state after every move,
    every event's player is flipped, flipped actions validate identically.
  - `OnlineSession` × 2 over `FakeRelay`: 50 random full matches (built-in and custom decks) with equal digests
    after every move and the same winner; rejoin mid-match reaches the same digest; block timeout; backstop; concede;
    rematch.
  - View: menu button enabled on the rival's turn; AI waits while paused; match runs as seat 1 with `verify_views`
    clean; fuse ends the turn; online panel states.
- **Server:** Vitest + `@cloudflare/vitest-pool-workers` (real DOs locally): host/join/queue, version and deck
  errors, numbering, wrong-seat rejection, block handshake + timeout, backstop, disconnect/rejoin/forfeit, rematch,
  desync, cleanup, flood guard.
- **End to end:** `wrangler dev` + two `tools/online_bot.gd` clients play full matches over real sockets
  (host/join and quick match) and must report the same winner and final digest. Manual check: browser export vs
  a desktop window against the local server.

## 8. Delivery

1. Engine additions, seat mirror, rival drivers, always-on menu — no network; vs AI plays as before.
2. Server and its tests (local).
3. Godot online layer, panel, in-match UI, bots and E2E against the local server.
4. Go live: the user runs `! npx wrangler login` once; deploy; put the `workers.dev` URL into `Online.SERVER_URL`;
   web export + push only when the user says so; optional Windows exe rebuild + release.

Checkpoints with screenshots after stages 1 and 3.
