#!/usr/bin/env bash
set -euo pipefail

# fc_thread_fixed.sh — Build and post a Farcaster thread (FIXED VERSION)
# This version properly handles file input and avoids JSON escaping issues

NEYNAR_BASE="https://api.neynar.com/v2/farcaster"
API_KEY="${NEYNAR_API_KEY:-}"
SIGNER="${NEYNAR_SIGNER_UUID:-}"
CHANNEL=""
DRY_RUN=false

usage() {
  cat <<'EOF'
Usage: fc_thread_fixed.sh --file ROOT_FILE [--channel ID] [--dry-run]

Builds a Farcaster thread:
- Reads root cast text from file (required)
- Subsequent casts as replies to build a thread
- Each child posted sequentially with correct parent hash

Options:
  --file PATH           Read root text from file (required, avoids shell quoting issues)
  --channel ID          Post to channel (e.g. "cryptoart", "base")
  --dry-run             Validate without posting

Note: This script reads root from file. Children can be passed as:
  fc_thread_fixed.sh --file root.txt -- "Child 1 text" "Child 2 text" ...
EOF
  exit 0
}

# Parse arguments
ROOT_FILE=""
CHILD_TEXTS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) ROOT_FILE="$2"; shift 2 ;;
    --channel) CHANNEL="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --help|-h) usage ;;
    *)
      # Everything else is a child cast
      CHILD_TEXTS+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$API_KEY" ]]; then
  echo '{"error":"NEYNAR_API_KEY not set"}' >&2
  exit 1
fi
if [[ -z "$SIGNER" ]]; then
  echo '{"error":"NEYNAR_SIGNER_UUID not set"}' >&2
  exit 1
fi
if [[ -z "$ROOT_FILE" ]]; then
  echo '{"error":"--file is required"}' >&2
  exit 1
fi
if [[ ! -f "$ROOT_FILE" ]]; then
  echo "{\"error\":\"Root file not found: $ROOT_FILE\"}" >&2
  exit 1
fi

# Read root text from file (preserving newlines and special chars)
# Using read with -d '' to preserve exact content
ROOT_TEXT=""
while IFS= read -r line || [ -n "$line" ]; do
  ROOT_TEXT+="$line"$'\n'
done < "$ROOT_FILE"

# Remove trailing newline
ROOT_TEXT="${ROOT_TEXT%$'\n'}"

# Dry run
if [[ "$DRY_RUN" = true ]]; then
  echo "Dry run - would post:"
  echo "Root (${#ROOT_TEXT} chars): ${ROOT_TEXT:0:100}..."
  echo "Children: ${#CHILD_TEXTS[@]} casts"
  echo "Channel: ${CHANNEL:-none}"
  exit 0
fi

# Build JSON body for root cast
# Use --arg with --rawfile to avoid shell escaping issues
POST_ROOT_BODY=$(jq -n --arg s "$SIGNER" --rawfile t "$ROOT_FILE" '{signer_uuid: $s, text: $t}')

if [[ -n "$CHANNEL" ]]; then
  POST_ROOT_BODY=$(echo "$POST_ROOT_BODY" | jq --arg c "$CHANNEL" '. + {channel_id: $c}')
fi

# Post root cast
echo "Posting root cast..."

RESPONSE=$(curl -sS --connect-timeout 10 --max-time 30 -w "\n%{http_code}" -X POST "$NEYNAR_BASE/cast" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$POST_ROOT_BODY")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
RESP_BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
  PARENT_HASH=$(echo "$RESP_BODY" | jq -r '.cast.hash')
  echo "✓ Root posted: $PARENT_HASH"
  echo "Root text length: ${#ROOT_TEXT} chars"
else
  echo "ERROR: Root cast failed"
  echo "$RESP_BODY" | jq -r --argjson s "$HTTP_CODE" '. + {status: $s}' >&2
  exit 1
fi

# Post children
CHILD_COUNT=0
for CHILD_TEXT in "${CHILD_TEXTS[@]}"; do
  CHILD_COUNT=$((CHILD_COUNT + 1))
  echo "Posting child $CHILD_COUNT/$((#CHILD_TEXTS[@]))..."

  # Build JSON for child cast
  POST_BODY=$(jq -n --arg s "$SIGNER" --arg t "$CHILD_TEXT" --arg p "$PARENT_HASH" '{signer_uuid: $s, text: $t, parent: $p}')

  if [[ -n "$CHANNEL" ]]; then
    POST_BODY=$(echo "$POST_BODY" | jq --arg c "$CHANNEL" '. + {channel_id: $c}')
  fi

  RESPONSE=$(curl -sS --connect-timeout 10 --max-time 30 -w "\n%{http_code}" -X POST "$NEYNAR_BASE/cast" \
    -H "x-api-key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$POST_BODY")

  HTTP_CODE=$(echo "$RESPONSE" | tail -1)
  RESP_BODY=$(echo "$RESPONSE" | sed '$d')

  if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
    CHILD_HASH=$(echo "$RESP_BODY" | jq -r '.cast.hash')
    echo "✓ Child $CHILD_COUNT posted: $CHILD_HASH"
    PARENT_HASH="$CHILD_HASH"
  else
    echo "ERROR: Child $CHILD_COUNT failed"
    echo "$RESP_BODY" | jq -r --argjson s "$HTTP_CODE" '. + {status: $s}' >&2
    exit 1
  fi

  # Small delay between posts to avoid rate limits
  if [[ $CHILD_COUNT -lt ${#CHILD_TEXTS[@]} ]]; then
    sleep 2
  fi
done

echo ""
echo "Thread complete!"
echo "Total casts: $((CHILD_COUNT + 1))"
echo "Root: $PARENT_HASH"
