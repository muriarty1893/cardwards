#!/usr/bin/env bash
# End-to-end online check: the real relay (wrangler dev, local) and two headless bots per pair.
# Pairs: host + join, then two quick-match bots. Both bots of a pair must finish normally with the
# same winner and the same final state digest.
#   bash tools/e2e_online.sh            (SERVER=wss://... to use a deployed relay instead)
set -euo pipefail
cd "$(dirname "$0")/.."

OUT=$(mktemp -d)
PORT=${PORT:-8787}
SERVER=${SERVER:-}
WPID=""

cleanup() {
  if [ -n "$WPID" ]; then kill -- "-$WPID" 2>/dev/null || true; fi
}
trap cleanup EXIT

if [ -z "$SERVER" ]; then
  SERVER="ws://127.0.0.1:$PORT"
  (cd server && WRANGLER_SEND_METRICS=false setsid npx wrangler dev --ip 127.0.0.1 --port "$PORT" > "$OUT/wrangler.log" 2>&1) &
  sleep 1
  WPID=$(pgrep -f "wrangler dev --ip 127.0.0.1 --port $PORT" | head -1 || true)
  WPID=$(ps -o pgid= "$WPID" 2>/dev/null | tr -d ' ' || true)
  for _ in $(seq 1 90); do
    curl -sf "http://127.0.0.1:$PORT/health" > /dev/null 2>&1 && break
    sleep 1
  done
  curl -sf "http://127.0.0.1:$PORT/health" > /dev/null || { echo "wrangler dev did not start"; cat "$OUT/wrangler.log"; exit 1; }
fi

bot() {
  godot --headless --path . --script res://tools/online_bot.gd -- --server="$SERVER" "$@"
}

compare() {
  python3 - "$1" "$2" <<'EOF'
import json, sys
a, b = (json.load(open(p)) for p in sys.argv[1:3])
print("  ", a)
print("  ", b)
ok = a["reason"] == "normal" == b["reason"] and a["winner"] == b["winner"] and a["digest"] == b["digest"] and a["digest"] != ""
sys.exit(0 if ok else 1)
EOF
}

echo "host + join"
bot --mode=host --deck=grove_guard --brain-seed=1 --out="$OUT/host.json" > "$OUT/host.log" 2>&1 &
HOST=$!
for _ in $(seq 1 120); do [ -s "$OUT/host.json.code" ] && break; sleep 0.5; done
[ -s "$OUT/host.json.code" ] || { echo "host never got a code"; cat "$OUT/host.log"; exit 1; }
CODE=$(cat "$OUT/host.json.code")
echo "  room $CODE"
bot --mode=join="$CODE" --deck=blaze_rush --brain-seed=2 --out="$OUT/join.json" > "$OUT/join.log" 2>&1 || { cat "$OUT/join.log"; exit 1; }
wait "$HOST" || { cat "$OUT/host.log"; exit 1; }
compare "$OUT/host.json" "$OUT/join.json" || { echo "host/join disagree"; exit 1; }

echo "quick match"
bot --mode=quick --deck=sugar_storm --brain-seed=3 --out="$OUT/q1.json" > "$OUT/q1.log" 2>&1 &
Q1=$!
sleep 1
bot --mode=quick --deck=deep_freeze --brain-seed=4 --out="$OUT/q2.json" > "$OUT/q2.log" 2>&1 || { cat "$OUT/q2.log"; exit 1; }
wait "$Q1" || { cat "$OUT/q1.log"; exit 1; }
compare "$OUT/q1.json" "$OUT/q2.json" || { echo "quick pair disagree"; exit 1; }

echo "E2E OK"
