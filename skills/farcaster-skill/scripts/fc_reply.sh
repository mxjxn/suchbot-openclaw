#!/usr/bin/env bash
set -euo pipefail

# fc_reply.sh — Reply to a specific cast hash with proper text handling
# This script properly escapes text for curl to avoid Unicode issues

NEYNAR_BASE="https://api.neynar.com/v2/farcaster"
API_KEY="${NEYNAR_API_KEY:-}"
SIGNER="${NEYNAR_SIGNER_UUID:-}"

usage() {
  cat <<'EOF'
Usage: fc_reply.sh --parent HASH --text "message" [--channel ID]

Options:
  --parent HASH          Parent cast hash to reply to (required)
  --text TEXT           Reply text (required)
  --channel ID          Post to a channel (e.g. "cryptoart")
  --api-key KEY          Neynar API key (or set NEYNAR_API_KEY)
  --signer UUID          Signer UUID (or set NEYNAR_SIGNER_UUID)
  -h, --help             Show this help

Example:
  fc_reply.sh --parent "0xabc123" --text "Great point!" --channel "cryptoart"
EOF
  exit 0
}

PARENT=""
TEXT=""
CHANNEL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --parent) PARENT="$2"; shift 2 ;;
    --text) TEXT="$2"; shift 2 ;;
    --channel) CHANNEL="$2"; shift 2 ;;
    --api-key) API_KEY="$2"; shift 2 ;;
    --signer) SIGNER="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
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
if [[ -z "$PARENT" ]]; then
  echo '{"error":"--parent is required"}' >&2
  exit 1
fi
if [[ -z "$TEXT" ]]; then
  echo '{"error":"--text is required"}' >&2
  exit 1
fi

# Build JSON body with jq to properly escape the text
# Using --arg s ensures special characters like apostrophes are properly escaped
BODY=$(jq -n --arg s "$SIGNER" --arg t "$TEXT" --arg p "$PARENT" '{signer_uuid: $s, text: $t, parent: $p}')

# Add channel if specified
if [[ -n "$CHANNEL" ]]; then
  BODY=$(echo "$BODY" | jq --arg c "$CHANNEL" '. + {channel_id: $c}')
fi

# Make the request
RESPONSE=$(curl -sS --connect-timeout 10 --max-time 30 -w "\n%{http_code}" -X POST "$NEYNAR_BASE/cast" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$BODY")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
RESP_BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
  HASH=$(echo "$RESP_BODY" | jq -r '.cast.hash')
  echo '{"success":true,"hash":"'"$HASH"'","text":"'"$TEXT"'"}'
else
  echo "$RESP_BODY" | jq --argjson s "$HTTP_CODE" '. + {status: $s}' >&2
  exit 1
fi
