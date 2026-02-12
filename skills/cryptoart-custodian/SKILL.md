---
name: cryptoart-custodian
description: >
  Research artists whose work appears in cryptoart.social listings. Use when featuring,
  researching a new listing, or prompted by cron/heartbeat. Output: research document + feature-ready content.
  Triggers on: artist research, feature artist, cryptoart listing, gallery artist.
---

# Cryptoart Custodian Skill

Research artists from cryptoart.social listings and produce feature-ready content. Depth over short-form. No hype, no presumptions about beauty. Ground statements in research.

## Dependencies

- **subgraph** — fetch listings (seller addresses)
- **farcaster-skill** — fc_user, fc_feed, fc_cast, fc_thread
- **web_search** — for links in bios

## Workflow

### 1. Source artists

**Option A:** Query subgraph for active listings. Extract unique seller addresses.

```graphql
query ActiveListings {
  listings(first: 20, where: { status: "ACTIVE" }, orderBy: createdAt, orderDirection: desc) {
    seller
    tokenAddress
    tokenId
    listingType
    initialAmount
    createdAt
  }
}
```

**Option B:** Use provided address (e.g. from a specific listing or request).

### 2. Lookup Farcaster

```bash
skills/farcaster-skill/scripts/fc_user.sh --address "0x..."
```

Get: fid, username, display_name, bio, pfp_url, verified_addresses.

### 3. Bio links

Extract URLs from bio. Use web_search or web_fetch for context (artist site, portfolio, etc.).

### 4. Cast history

```bash
skills/farcaster-skill/scripts/fc_feed.sh --fid <fid> --limit 20
```

Note themes, projects, style, recurring topics.

### 5. Research doc

Write to `research/artists/<address>.md` using the template below.

### 6. Feature content

Draft thread or cast with depth. No hype, no presumptions. Ground in research. Post to /cryptoart via `fc_cast.sh --channel cryptoart` or `fc_thread.sh --channel cryptoart`.

## Research doc template

`research/artists/` (create if needed). File: `research/artists/<address>.md`

```markdown
# Artist: [address]

## Farcaster
- **FID:** 
- **Username:** @
- **Bio:** 

## Links (from bio)
- [URL]: [brief summary from web_search]

## Cast themes
- 

## Open questions
- 

## Last updated
- 
```

## Todos (when running research)

- [ ] Query subgraph for listings
- [ ] Extract seller address(es)
- [ ] fc_user.sh --address
- [ ] Extract bio links
- [ ] web_search for links
- [ ] fc_feed.sh --fid
- [ ] Write research doc
- [ ] Draft feature content
- [ ] Post to /cryptoart (if approved)

## References

- [references/subgraph-listings.md](references/subgraph-listings.md) — listing queries
- [references/neynar-user-feed.md](references/neynar-user-feed.md) — fc_user, fc_feed usage
