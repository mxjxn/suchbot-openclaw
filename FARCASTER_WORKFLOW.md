# Farcaster Workflow & Best Practices

This document outlines workflows and lessons learned for effective Farcaster casting, research, and cross-platform communication.

---

## Core Principles

1. **Farcaster is public, Telegram is private**
   - Never bridge contexts between platforms
   - One is a conversation with you (direct), the other is public conversation with the world
   - Reply in the platform where the conversation happened

2. **Casts are standalone pieces**
   - Each cast should work independently without requiring context from Telegram
   - Include relevant context within the cast itself
   - Don't rely on external context for meaning

3. **Threads should have substance**
   - "Topic: [Title]" as a standalone line is insufficient
   - Each cast in a thread should have actual content
   - Provide above-the-fold context when relevant

4. **Research depth over surface claims**
   - Research both sides of controversial topics
   - Distinguish between confirmed facts and speculation
   - Cite sources with URLs where available

5. **Git hygiene**
   - Batch related changes into meaningful commits
   - Describe what was accomplished and why
   - Keep repo history clean

---

## Casting Workflow

### Before Posting
1. **Preview content**: Read cast text to ensure clarity
2. **Check for embeds/images**: Ensure no broken links
3. **Use thread script first**: `fc_thread.sh` is designed for this
4. **If script fails**: Fall back to manual thread building using `fc_reply.sh`

### Building Threads (Manual Fallback)
1. Cast first piece: `fc_cast.sh --text "..."`
2. Get hash from response
3. Reply to that hash: `fc_reply.sh --parent <hash> --text "..."`
4. Repeat for subsequent casts
5. Use `--channel` flag consistently if posting to /cryptoart

### Common Mistakes to Avoid
- ❌ Using "Topic:" as standalone lines (context-free fragments)
- ❌ Creating threads without checking if first cast posted successfully
- ❌ Replying to my own casts in Telegram instead of casting corrections
- ❌ Saying "I see what happened..." with explanations for context (corrections should be direct casts)

### Formatting Best Practices
- Each cast should be a complete thought
- Use proper capitalization (begin sentences properly)
- Include necessary context within the cast
- Don't bury important information in thread fragments

---

## Research Workflow

### Investigation Process
1. **Identify claim**: What's being alleged or asserted?
2. **Seek primary sources**: Official announcements, platform docs, onchain data
3. **Cross-reference**: Multiple sources to verify or add nuance
4. **Track uncertainty**: Explicitly note what's unknown or speculative
5. **Avoid amplification**: Research should reveal, not reinforce narratives

### Documentation Structure
1. **Timeline**: Document chronological events with dates
2. **Controversies**: List specific incidents and what's alleged
3. **Defenses/Proponents**: Document counter-arguments and success stories
4. **Metrics**: Include numbers when available (TVL, volume, users)
5. **Sources**: Cite URLs for verification

### Balancing Perspectives
- **Critics**: What's being claimed as problems?
- **Defenders**: What's being argued as benefits?
- **Both sides**: Present fair picture, let reader evaluate
- **Distinguish opinions from facts**: "X said" vs "X did"

---

## Cross-Platform Communication

### Telegram ↔ Farcaster Separation
- **Never acknowledge**: Don't say "Thanks for the feedback on Telegram" on Farcaster
- **Don't explain**: Don't reference Telegram conversations on Farcaster
- **Separate contexts**: Telegram is for your eyes only; Farcaster is public
- **Self-correction only**: If I make a mistake on Farcaster, cast the correction there. Don't mention Telegram.

### Telegram Best Practices
- Be concise in responses
- Report what was done, not how I did it (avoiding tool noise)
- Don't bridge Farcaster content to Telegram unless you specifically ask

---

## Image & Embed Attachments

### Current Status
- ❌ **Not yet learned**: How to attach images to casts
- ❌ **Not yet learned**: How to embed links or external content
- ✅ **Know**: Text-based casting works well

### Action Item
- When mxjxn teaches image attachment workflow, test it before using publicly
- Document learned patterns in this file

---

## Tools & Scripts

### Farcaster Skill Scripts
- `fc_cast.sh` - Post a single cast
- `fc_reply.sh` - Reply to a cast (parent hash required)
- `fc_thread.sh` - Build and post a thread
- `fc_feed.sh` - Get feed from channel/user
- `fc_search.sh` - Search for casts (keyword)

### Known Issues
- `fc_thread.sh` can fail with cryptic errors
- Fallback: Use manual threading with `fc_reply.sh` if needed
- Check script output for success before proceeding

### Environment Variables Required
- `NEYNAR_API_KEY` - API key for Neynar v2
- `NEYNAR_SIGNER_UUID` - Signer UUID for write operations

---

## Git Commit Patterns

### Batch Related Changes
- Research updates on same topic → One comprehensive commit
- Message: "Research: [topic] - [what was added/updated]"

### Example Commit Messages
- "Research: NFT platform closures with proponents and new controversies"
- "Research: Updated NFT platform closures with proponents and new controversies"

### Commit Quality
- Describe substantive accomplishments
- Note files created/modified
- Explain rationale for changes

---

## Learning from Mistakes

### Research Performance (Feb 13, 2026)
**What went well:**
- Deep investigation on Zora/Base controversies
- Balanced coverage of both criticisms and defenses
- Created comprehensive research folder (9 files)
- Multiple web_search calls to gather data
- Updated files iteratively with new findings

**What could improve:**
- Initial reply over-explained the research process (too much tool detail)
- File organization: Created `ongoing-research.md` then kept editing it, creating version noise in git history
- No upfront summary after research completion

### Cast Formatting (Feb 13, 2026)
**Mistake identified:**
- Posted "Topic: Frictionless Infrastructure" as standalone line instead of full cast with context

**Should have been:**
- Cast full thought on frictionless infrastructure as first cast of thread
- Then "Current narrative..." as second cast
- "But this binary view..." as third cast, etc.
- Each cast independent but connected through thread structure

---

## Tool Preferences

### When to Use Web Search
- Factual queries ("X controversy", "platform shutdown dates")
- Multiple search rounds to build comprehensive picture
- Current events first, historical context second

### When to Use Scripts
- `fc_thread.sh` for morning thoughts or structured content
- `fc_reply.sh` for corrections or thread additions
- `fc_feed.sh` for monitoring /cryptoart
- `fc_search.sh` for finding mentions or topics

### When NOT to Use Scripts
- Simple replies that don't require chaining
- Research documentation (use workspace files instead)

---

## Reference

### Workspace Structure
```
/root/.openclaw/workspace/
├── skills/farcaster-skill/       # Farcaster scripts and SKILL.md
├── research/                          # Research folders
├── FARCASTER_WORKFLOW.md         # This file
└── [project folders]               # cryptoart-studio, erc8004-setup, etc.
```

### Key Documentation
- `SOUL.md` - Agent identity and persona
- `USER.md` - User profile and preferences
- `HEARTBEAT.md` - Heartbeat procedures
- `AGENTS.md` - Agent workspace overview
- `TOPICS.md` - Active topics tracking
- `PEOPLE.md` - People database
- `MEMORY.md` - Long-term curated memories

---

**Last Updated**: 2026-02-13 18:20 UTC
