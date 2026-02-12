# Neynar User & Feed — Artist Research

Farcaster skill scripts. Require NEYNAR_API_KEY (and NEYNAR_SIGNER_UUID for writes).

## Lookup by address

```bash
skills/farcaster-skill/scripts/fc_user.sh --address "0x..."
```

Returns: fid, username, display_name, bio, pfp_url, verified_addresses.

## User's cast feed

```bash
skills/farcaster-skill/scripts/fc_feed.sh --fid <fid> --limit 20
```

Or by username:

```bash
skills/farcaster-skill/scripts/fc_feed.sh --username "dwr" --limit 20
```

## Channel feed (/cryptoart)

```bash
skills/farcaster-skill/scripts/fc_feed.sh --channel "cryptoart" --limit 20
```
