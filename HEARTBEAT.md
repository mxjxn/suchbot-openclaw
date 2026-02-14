# HEARTBEAT.md

Read this file during heartbeat. Follow **only** the section for your role (Main, Curator, Writer, Cat, or Rat).

**Track:** `memory/heartbeat-state.json` with lastChecks. Heartbeat vs cron: batch checks → heartbeat; exact timing / isolated task → cron.

---

## Main

- **Memory maintenance:** Refresh TOPICS.md (move resolved to archive, add new conclusions). Update PEOPLE.md. Review MEMORY.md.
- **Routing:** Check for messages that address Cat, Rat, Curator, or Writer by name. Forward via sessions_send.
- **Boston News Digest:** When triggered by cron (next-heartbeat), search Boston news, summarize, send to mxjxn.

---

## Curator

- **Custodian cycle:** Check /cryptoart channel feed (fc_feed.sh --channel cryptoart). Scan recent conversations for topics to add to TOPICS.md.
- Check for @suchbot or @mxjxn mentions that need a response.
- Any artist to research? Update PEOPLE.md. Use cryptoart-custodian skill for research workflow.
- **Cron tasks:** Ending Soon Auctions, Weekly Artist Research run as system events in your session.

---

## Writer

- **Content drafting:** When triggered by cron (Morning Cast, Afternoon Cast, Nightly Digest, Daily Journal Blog), follow the system event.
- **Morning/Afternoon thought:** Pick topic from TOPICS.md. Use `scripts/morning_thought.sh` for substantive content. Post to /cryptoart via fc_thread.sh.
- **Core principle:** Elaborate, extend, or challenge — never repeat word-for-word from memory.
- **Nightly digest:** Summarize day (custodian work, dev work, channel activity). Post thread to /cryptoart.
- **Daily journal:** Write to suchbot-website/src/content/blog/YYYY-MM-DD-daily-journal.md.

### Blog Post Rules

**MANDATORY:** All blog posts must have:
- **Clever/unique title** — No generic titles like "Update" or "Changes". Make it memorable.
- Proper frontmatter: `title`, `author: suchbot`, `date: YYYY-MM-DD`

---

## Cat

- **Dev cycle:** Check suchbot-website, mini-apps, prototypes for TODOs, git status, open PRs, CI.
- **suchbot-website rule:** Any changes MUST build successfully, then be committed and pushed. Run `npm run build`, then `git add && git commit && git push`.
- Propose or execute if approved.
- Check `memory/agent-tasks.json` for tasks assigned to you.

---

## Rat

- **Dev cycle:** Check cryptoart-studio, erc8004-setup for TODOs, git status, open PRs, CI.
- Propose or execute if approved.
- Check `memory/agent-tasks.json` for tasks assigned to you.
