#!/usr/bin/env bash
set -euo pipefail

# fc_get_conversation.sh — Retrieve full Farcaster conversation thread
# Usage: fc_get_conversation.sh [options]

NEYNAR_BASE="https://api.neynar.com/v2/farcaster"
API_KEY="${NEYNAR_API_KEY:-}"

usage() {
  cat <<'EOF'
Usage: fc_get_conversation.sh <identifier> [options]

Arguments:
  <identifier>          Cast hash (0x...) or Farcaster URL (required)
  --type TYPE           "hash" or "url" (default: auto-detect)
  --reply-depth N       Depth of replies to fetch (default: 2)
  --parent-casts        Include all parent casts in chronological order
  --no-parent-casts     Exclude parent casts from results
  --viewer-fid FID      FID for viewer context (respects mutes/blocks)
  --sort TYPE           Sort type: chron, desc_chron, algorithmic (default: chron)
  --fold DIR            Fold low-quality replies: above, below (default: none)
  --limit LIMIT         Number of casts to fetch (1-50, default: 20)
  --cursor CURSOR       Pagination cursor
  --api-key KEY         Neynar API key (or set NEYNAR_API_KEY env var)

Examples:
  # Get conversation by cast hash
  fc_get_conversation.sh 0xabc123...

  # Get conversation by Farcaster URL
  fc_get_conversation.sh "https://warpcast.com/username/0xabc..."

  # Get conversation with full reply depth and parent casts
  fc_get_conversation.sh 0xabc123... --reply-depth 3 --parent-casts

  # Get conversation for a user with viewer context
  fc_get_conversation.sh 0xabc123... --viewer-fid 4905

Output: JSON object with "conversation" array and optional "next" cursor.
EOF
  exit 0
}

# Parse arguments
IDENTIFIER=""
TYPE=""
REPLY_DEPTH=""
INCLUDE_PARENTS=""
VIEWER_FID=""
SORT_TYPE=""
FOLD=""
LIMIT=20
CURSOR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    --type) TYPE="$2"; shift 2 ;;
    --reply-depth) REPLY_DEPTH="$2"; shift 2 ;;
    --parent-casts) INCLUDE_PARENTS="true"; shift ;;
    --no-parent-casts) INCLUDE_PARENTS="false"; shift ;;
    --viewer-fid) VIEWER_FID="$2"; shift 2 ;;
    --sort) SORT_TYPE="$2"; shift 2 ;;
    --fold) FOLD="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    --cursor) CURSOR="$2"; shift 2 ;;
    --api-key) API_KEY="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *)
      if [[ -z "$IDENTIFIER" ]]; then
        IDENTIFIER="$1"
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      shift ;;
  esac
done

if [[ -z "$IDENTIFIER" ]]; then
  echo '{"error":"Cast identifier (hash or URL) is required","status":400}' >&2
  exit 1
fi

if [[ -z "$API_KEY" ]]; then
  echo '{"error":"NEYNAR_API_KEY not set","status":401}' >&2
  exit 1
fi

# Auto-detect type if not specified
if [[ -z "$TYPE" ]]; then
  if [[ "$IDENTIFIER" =~ ^0x[a-fA-F0-9]+$ ]]; then
    TYPE="hash"
  elif [[ "$IDENTIFIER" =~ ^https?:// ]]; then
    TYPE="url"
  else
    echo '{"error":"Cannot auto-detect type -- specify --type hash or --type url","status":400}' >&2
    exit 1
  fi
fi

# Build query string
QUERY="identifier=${IDENTIFIER}&type=${TYPE}&limit=${LIMIT}"

if [[ -n "$REPLY_DEPTH" ]]; then
  QUERY+="&reply_depth=${REPLY_DEPTH}"
fi

if [[ -n "$INCLUDE_PARENTS" ]]; then
  QUERY+="&include_chronological_parent_casts=${INCLUDE_PARENTS}"
fi

if [[ -n "$VIEWER_FID" ]]; then
  QUERY+="&viewer_fid=${VIEWER_FID}"
fi

if [[ -n "$SORT_TYPE" ]]; then
  QUERY+="&sort_type=${SORT_TYPE}"
fi

if [[ -n "$FOLD" ]]; then
  QUERY+="&fold=${FOLD}"
fi

if [[ -n "$CURSOR" ]]; then
  QUERY+="&cursor=${CURSOR}"
fi

# Make API request (GET with query parameters)
RESPONSE=$(curl -sS --connect-timeout 10 --max-time 30 -w "\n%{http_code}" \
  -X GET "${NEYNAR_BASE}/cast/conversation?${QUERY}" \
  -H "api_key: $API_KEY")

# Split response body and HTTP code
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
  echo "$BODY"
else
  echo "$BODY" | jq -c '{error: (.message // .details // "Unknown error"), status: (.status // '"$HTTP_CODE"')}' >&2
  exit 1
fi
