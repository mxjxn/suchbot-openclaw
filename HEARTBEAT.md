# HEARTBEAT.md

**Custodian cycle:**
- Check /cryptoart channel feed (fc_feed.sh --channel cryptoart). Scan recent conversations for topics to add to TOPICS.md.
- Check for @suchbot or @mxjxn mentions that need a response.
- Any artist to research? Update PEOPLE.md. Use cryptoart-custodian skill for research workflow.

**Dev cycle:** Check cryptoart-studio, erc8004-setup, web for TODOs, git status, open PRs, CI. Propose or execute if approved.

**Memory maintenance:** Refresh TOPICS.md (move resolved to archive, add new conclusions). Update PEOPLE.md. Review MEMORY.md.

**Morning thought generation:**
When triggered by system: Use `scripts/morning_thought.sh` for substantive content.
Process: Read TOPICS.md → Identify themes → Research → Draft NEW perspective → Post.
Core principle: Elaborate, extend, or challenge — never repeat word-for-word from memory.

**Track:** `memory/heartbeat-state.json` with lastChecks. Heartbeat vs cron: batch checks → heartbeat; exact timing / isolated task → cron.
