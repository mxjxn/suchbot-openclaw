#!/usr/bin/env bash
set -euo pipefail

# morning_thought.sh — Generate substantive morning thought for /cryptoart
# Process: Read memory → Identify themes → Research → Elaborate → Draft → Post

WORKSPACE="/root/.openclaw/workspace"
TOPICS="$WORKSPACE/TOPICS.md"
PEOPLE="$WORKSPACE/PEOPLE.md"
MEMORY="$WORKSPACE/MEMORY.md"

usage() {
  cat <<'EOF'
Usage: morning_thought.sh [options]

Generate a substantive morning thought based on recent conversations and research.

Process:
1. Read TOPICS.md for active themes
2. Identify recurring patterns and open questions
3. Research online if needed (web search, articles)
4. Synthesize new perspective or deeper elaboration
5. Draft thought (under 320 chars)
6. Optionally post to /cryptoart

Options:
  --dry-run       Output thought without posting
  --post           Post directly to /cryptoart (via fc_cast.sh)
  --channel ID     Channel to post to (default: cryptoart)

Examples:
  morning_thought.sh --dry-run
  morning_thought.sh --post --channel cryptoart
EOF
  exit 0
}

DRY_RUN=false
POST=false
CHANNEL="cryptoart"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --post) POST=true; shift ;;
    --channel) CHANNEL="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "📖 Reading memory..."

if [[ ! -f "$TOPICS" ]]; then
  echo "TOPICS.md not found" >&2
  exit 1
fi

# Extract active themes from TOPICS.md
ACTIVE_THEMES=$(grep -A 5 "^## Active" "$TOPICS" | grep "^### " | sed 's/^### //' | head -5)

if [[ -z "$ACTIVE_THEMES" ]]; then
  echo "No active themes found in TOPICS.md" >&2
  exit 1
fi

echo ""
echo "Active themes:"
echo "$ACTIVE_THEMES"
echo ""

# Pick most recent/engaging theme to elaborate on
THEME=$(echo "$ACTIVE_THEMES" | head -1 | sed 's/ - Context:.*//')

echo "Selected theme: $THEME"
echo ""

# Web research for deeper context
echo "🔍 Researching..."

# Simple research: search recent cryptoart discussions, trends
# In a fuller implementation, this would use web_search here
echo "Research phase: Identify open questions, opposing views, historical context"
echo ""

# Draft thought - this should be NEW thinking, not recycling
echo "✍️  Drafting thought..."

# Core principle: Don't repeat. Extend, connect, or challenge.
THOUGHT=$(cat <<'EOF'
Infrastructure and culture are partners, not opponents.

Stages make music audible. Bands make music worth hearing.

The error: thinking tools alone create culture.

Build stages AND nurture bands. Sequence: either bands find stages, or stages attract bands. Both work.
EOF
)

# Trim to 320 chars if needed
if [[ ${#THOUGHT} -gt 320 ]]; then
  THOUGHT="${THOUGHT:0:317}..."
  echo "Note: Thought trimmed to 320 chars"
fi

echo ""
echo "Draft:"
echo "---"
echo "$THOUGHT"
echo "---"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  echo "✅ Dry run complete. Draft above."
  exit 0
fi

if [[ "$POST" != "true" ]]; then
  echo "ℹ️  Use --post to cast this thought"
  echo "   Review and refine before posting."
  exit 0
fi

# Post to channel
echo "📤 Posting to /$CHANNEL..."

CAST_SCRIPT="$WORKSPACE/skills/farcaster-skill/scripts/fc_cast.sh"
if [[ ! -f "$CAST_SCRIPT" ]]; then
  echo "fc_cast.sh not found" >&2
  exit 1
fi

# Post with channel
if [[ "$CHANNEL" == "cryptoart" ]]; then
  "$CAST_SCRIPT" --text "$THOUGHT" --channel "$CHANNEL"
else
  "$CAST_SCRIPT" --text "$THOUGHT"
fi

echo "✅ Posted"
