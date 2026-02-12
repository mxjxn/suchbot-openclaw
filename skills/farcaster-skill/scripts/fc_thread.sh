#!/usr/bin/env bash
set -euo pipefail

# fc_thread.sh — Build and post a Farcaster thread
# Posts root cast, then child casts as replies to build a thread.

NEYNAR_BASE="https://api.neynar.com/v2/farcaster"
API_KEY="${NEYNAR_API_KEY:-}"
SIGNER="${NEYNAR_SIGNER_UUID:-}"
CHANNEL=""
CHILD_TEXTS=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

usage() {
  cat <<'EOF'
Usage: fc_thread.sh <root_message> [child1] [child2] ...

Builds a Farcaster thread:
- First cast is the root message
- Subsequent casts are replies to previous cast (builds thread)
- Each child posted sequentially with correct parent hash

Options:
  --api-key KEY        Neynar API key (or set NEYNAR_API_KEY)
  --signer UUID       Signer UUID (or set NEYNAR_SIGNER_UUID)
  --channel ID        Post to channel (e.g. "cryptoart", "base")

Child format (each child):
  --text TEXT           Plain text content
  --listing LISTING    Format: "• @author — Name (TYPE) — price — link"
  --artwork HASH       Embed a cast by hash
  --auction TYPE        "auction" or "fixed" for duration display

Examples:
  # Simple thread
  fc_thread.sh "Good morning! Here's what's happening:"
    "Crypto market is up 📈"
    "New art dropped today 🎨"

  # Thread with auction listings
  fc_thread.sh "📊 Cryptoart.Auction Morning Recap" \
    --listing "@sosogutter — 260207A (auction, 24h) — 0.01 ETH — https://cryptoart.social/listing/115" \
    --listing "@okeaniderya.eth — untitled (fixed) — 0.131 ETH — https://cryptoart.social/listing/114"

  # Thread with artwork embeds
  fc_thread.sh "Featured pieces this week:" \
    --artwork "0xabc...123" \
    --artwork "0xdef...456"

  # Thread in /cryptoart channel
  fc_thread.sh --channel cryptoart "Morning thoughts:" --text "..."

EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --api-key) API_KEY="$2"; shift 2 ;;
    --signer) SIGNER="$2"; shift 2 ;;
    --channel) CHANNEL="$2"; shift 2 ;;
    --text) CHILD_TEXTS+=("$2"); shift 2 ;;
    --listing) LISTINGS+=("$2"); shift 2 ;;
    --artwork) ARTWORKS+=("$2"); shift 2 ;;
    --auction) AUCTION_TYPE="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) break ;;
  esac
done

if [[ -z "$API_KEY" ]]; then
  echo '{"error":"NEYNAR_API_KEY not set. Use --api-key or export NEYNAR_API_KEY."}' >&2
  exit 1
fi

if [[ -z "$SIGNER" ]]; then
  echo '{"error":"NEYNAR_SIGNER_UUID not set. Use --signer or export NEYNAR_SIGNER_UUID."}' >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  echo '{"error":"Root message required"}' >&2
  exit 1
fi

ROOT_TEXT="$1"
shift  # Remove root from args, now $@ are children

# Post root cast
echo -e "${GREEN}Posting root cast...${NC}"

POST_ROOT_BODY=$(jq -n --arg s "$SIGNER" --arg t "$ROOT_TEXT" '{signer_uuid: $s, text: $t}')
[[ -n "$CHANNEL" ]] && POST_ROOT_BODY=$(echo "$POST_ROOT_BODY" | jq --arg c "$CHANNEL" '. + {channel_id: $c}')

RESPONSE=$(curl -sS --connect-timeout 10 --max-time 30 -w "\n%{http_code}" -X POST "$NEYNAR_BASE/cast" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d "$POST_ROOT_BODY")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
RESP_BODY=$(echo "$RESPONSE" | sed '$d')

if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
  PARENT_HASH=$(echo "$RESP_BODY" | jq -r '.cast.hash')
  echo -e "${GREEN}✓ Root cast posted${NC}"
  echo -e "  Hash: $PARENT_HASH"
  echo ""
else
  echo "$RESP_BODY" | jq -r --argjson s "$HTTP_CODE" '. + {status: $s}' >&2
  exit 1
fi

# Process and post children
CHILD_COUNT=0
for arg in "$@"; do
  # Skip processing if there are no children after root
  if [[ $# -eq 0 ]]; then
    echo -e "${YELLOW}No children to process. Thread complete with root cast only.${NC}"
    break
  fi
  case "$arg" in
    --text)
      CHILD_TEXT="$2"
      shift 2

      # Post child cast as reply
      echo -e "${GREEN}Posting child #$((CHILD_COUNT + 1))...${NC}"

      POST_BODY=$(jq -n --arg s "$SIGNER" --arg t "$CHILD_TEXT" --arg p "$PARENT_HASH" '{signer_uuid: $s, text: $t, parent: $p}')
      [[ -n "$CHANNEL" ]] && POST_BODY=$(echo "$POST_BODY" | jq --arg c "$CHANNEL" '. + {channel_id: $c}')

      RESPONSE=$(curl -sS --connect-timeout 10 --max-time 30 -w "\n%{http_code}" -X POST "$NEYNAR_BASE/cast" \
        -H "x-api-key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$POST_BODY")

      HTTP_CODE=$(echo "$RESPONSE" | tail -1)
      RESP_BODY=$(echo "$RESPONSE" | sed '$d')

      if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
        CHILD_HASH=$(echo "$RESP_BODY" | jq -r '.cast.hash')
        echo -e "${GREEN}✓ Child cast posted${NC}"
        echo -e "  Hash: $CHILD_HASH"

        # Update parent hash for next child
        PARENT_HASH="$CHILD_HASH"
        CHILD_COUNT=$((CHILD_COUNT + 1))

        # Small delay between posts to avoid rate limits
        if [[ $CHILD_COUNT -lt $# ]]; then
          sleep 1
        fi
      else
        echo "$RESP_BODY" | jq -r --argjson s "$HTTP_CODE" '. + {status: $s}' >&2
        exit 1
      fi
      ;;

    --listing)
      LISTING_TEXT="${LISTINGS[0]}"
      shift
      LISTINGS=("${LISTINGS[@]:1}")  # Remove first element

      # Post listing cast
      echo -e "${GREEN}Posting listing cast...${NC}"

      POST_BODY=$(jq -n --arg s "$SIGNER" --arg t "$LISTING_TEXT" --arg p "$PARENT_HASH" '{signer_uuid: $s, text: $t, parent: $p}')
      [[ -n "$CHANNEL" ]] && POST_BODY=$(echo "$POST_BODY" | jq --arg c "$CHANNEL" '. + {channel_id: $c}')

      RESPONSE=$(curl -sS --connect-timeout 10 --max-time 30 -w "\n%{http_code}" -X POST "$NEYNAR_BASE/cast" \
        -H "x-api-key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$POST_BODY")

      HTTP_CODE=$(echo "$RESPONSE" | tail -1)
      RESP_BODY=$(echo "$RESPONSE" | sed '$d')

      if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
        LISTING_HASH=$(echo "$RESP_BODY" | jq -r '.cast.hash')
        echo -e "${GREEN}✓ Listing cast posted${NC}"
        echo -e "  Hash: $LISTING_HASH"

        # Update parent hash for next cast
        PARENT_HASH="$LISTING_HASH"
        CHILD_COUNT=$((CHILD_COUNT + 1))

        sleep 1
      else
        echo "$RESP_BODY" | jq -r --argjson s "$HTTP_CODE" '. + {status: $s}' >&2
        exit 1
      fi
      ;;

    --artwork)
      ARTWORK_HASH="${ARTWORKS[0]}"
      ARTWORK_TEXT="${ARTWORKS[1]}"
      shift
      ARTWORKS=("${ARTWORKS[@]:2}")  # Remove first two elements

      # Post artwork embed cast
      echo -e "${GREEN}Posting artwork embed...${NC}"

      POST_BODY=$(jq -n --arg s "$SIGNER" --arg p "$PARENT_HASH" --argjson e '[{"cast_id": {"hash": "'"${ARTWORK_HASH}"'"'}}]' '{signer_uuid: $s, parent: $p, embeds: $e}')
      [[ -n "$CHANNEL" ]] && POST_BODY=$(echo "$POST_BODY" | jq --arg c "$CHANNEL" '. + {channel_id: $c}')

      RESPONSE=$(curl -sS --connect-timeout 10 --max-time 30 -w "\n%{http_code}" -X POST "$NEYNAR_BASE/cast" \
        -H "x-api-key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "$POST_BODY")

      HTTP_CODE=$(echo "$RESPONSE" | tail -1)
      RESP_BODY=$(echo "$RESPONSE" | sed '$d')

      if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
        EMBED_HASH=$(echo "$RESP_BODY" | jq -r '.cast.hash')
        echo -e "${GREEN}✓ Artwork embed cast posted${NC}"
        echo -e "  Hash: $EMBED_HASH"

        # Update parent hash for next cast
        PARENT_HASH="$EMBED_HASH"
        CHILD_COUNT=$((CHILD_COUNT + 1))

        sleep 1
      else
        echo "$RESP_BODY" | jq -r --argjson s "$HTTP_CODE" '. + {status: $s}' >&2
        exit 1
      fi
      ;;

    --auction)
      # Set auction type for display
      AUCTION_DISPLAY="$2"
      shift
      ;;

    *)
      # Unknown argument, skip
      shift
      ;;
  esac
done

echo -e "${GREEN}Thread complete!${NC}"
echo -e "  Total casts: $((CHILD_COUNT + 1))"
