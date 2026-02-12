---
name: subgraph
description: >
  Query The Graph subgraph for marketplace and creator data (listings, purchases, bids,
  offers, collections, tokens). Use when you need to: (1) check subgraph sync status,
  (2) fetch active or finalized listings, (3) get purchases or bids for a listing,
  (4) look up collections or tokens, (5) query offers or escrow. All requests are
  GraphQL POSTs with Bearer token from GRAPH_API_KEY.
metadata:
  openclaw:
    emoji: "📊"
    requires: { env: ["GRAPH_API_KEY"] }
    primaryEnv: "GRAPH_API_KEY"
---

# Subgraph skill

Query the marketplace + creator subgraph on The Graph (Gateway). All calls are **POST** with JSON body `{ "query", "operationName", "variables" }` and **Authorization: Bearer &lt;GRAPH_API_KEY&gt;** (from `.env`).

**Endpoint (fixed):**

```
https://gateway.thegraph.com/api/subgraphs/id/BFHnXWdnn9gt4tK2jag8enxFcG23Lu43hXaXNmgc44mV
```

## Setup

Ensure `GRAPH_API_KEY` is set (e.g. in `.env`). Do not read or write `.env` from the agent; ask the user to set it.

```bash
# Example (user runs this, not the agent)
export GRAPH_API_KEY="your-graph-api-key"
```

When using an HTTP tool (e.g. `web` or `invoke-http`), send:

- **Method:** POST  
- **URL:** `https://gateway.thegraph.com/api/subgraphs/id/BFHnXWdnn9gt4tK2jag8enxFcG23Lu43hXaXNmgc44mV`  
- **Headers:**  
  - `Content-Type: application/json`  
  - `Authorization: Bearer $GRAPH_API_KEY`  
- **Body:** JSON with `query`, optional `operationName`, optional `variables: {}`

---

## 1. Check sync status

Use `_meta { block { number } }` to see the last indexed block (confirms subgraph is syncing).

```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GRAPH_API_KEY" \
  -d '{"query": "{ _meta { block { number } } }", "operationName": "Subgraphs", "variables": {}}' \
  https://gateway.thegraph.com/api/subgraphs/id/BFHnXWdnn9gt4tK2jag8enxFcG23Lu43hXaXNmgc44mV
```

**GraphQL query:**

```graphql
query Subgraphs {
  _meta {
    block {
      number
    }
  }
}
```

---

## 2. Listings

**Active listings (first 10):**

```graphql
query ActiveListings {
  listings(first: 10, where: { status: "ACTIVE" }, orderBy: createdAt, orderDirection: desc) {
    id
    listingId
    marketplace
    seller
    tokenAddress
    tokenId
    tokenSpec
    listingType
    initialAmount
    totalAvailable
    totalSold
    startTime
    endTime
    erc20
    status
    hasBid
    finalized
    currentBidAmount
    createdAt
  }
}
```

**Single listing by id (listingId):**

```graphql
query Listing($id: ID!) {
  listing(id: $id) {
    id
    listingId
    marketplace
    seller
    tokenAddress
    tokenId
    status
    initialAmount
    totalSold
    currentBidder
    currentBidAmount
    createdAt
    updatedAt
  }
}
```

Variables: `{ "id": "12345" }` (use the listing’s id, usually numeric string).

**Listings by seller address:**

```graphql
query ListingsBySeller($seller: Bytes!) {
  listings(first: 20, where: { seller: $seller }, orderBy: createdAt, orderDirection: desc) {
    id
    listingId
    tokenAddress
    tokenId
    status
    initialAmount
    totalSold
    createdAt
  }
}
```

Variables: `{ "seller": "0x..." }` (lowercase hex with 0x).

---

## 3. Purchases

**Purchases for a listing:**

```graphql
query PurchasesForListing($listingId: BigInt!) {
  purchases(first: 50, where: { listingId: $listingId }, orderBy: blockNumber, orderDirection: desc) {
    id
    listingId
    buyer
    count
    amount
    timestamp
    blockNumber
    transactionHash
  }
}
```

Variables: `{ "listingId": "12345" }` (string).

**Recent purchases (global):**

```graphql
query RecentPurchases {
  purchases(first: 20, orderBy: blockNumber, orderDirection: desc) {
    id
    listingId
    buyer
    count
    amount
    blockNumber
    transactionHash
  }
}
```

---

## 4. Bids

**Bids for a listing:**

```graphql
query BidsForListing($listingId: BigInt!) {
  bids(first: 50, where: { listingId: $listingId }, orderBy: blockNumber, orderDirection: desc) {
    id
    listingId
    bidder
    amount
    timestamp
    blockNumber
    transactionHash
  }
}
```

---

## 5. Offers

**Offers for a listing:**

```graphql
query OffersForListing($listingId: BigInt!) {
  offers(first: 50, where: { listingId: $listingId }, orderBy: blockNumber, orderDirection: desc) {
    id
    listingId
    offerer
    amount
    status
    timestamp
    blockNumber
    transactionHash
  }
}
```

---

## 6. Collections & tokens (Creator Core)

**Collection by id (contract address):**

```graphql
query Collection($id: ID!) {
  collection(id: $id) {
    id
    address
    name
    symbol
    totalSupply
    createdAt
    createdAtBlock
  }
}
```

Variables: `{ "id": "0x..." }` (lowercase contract address).

**Tokens in a collection:**

```graphql
query TokensInCollection($collection: String!) {
  tokens(first: 100, where: { collection: $collection }, orderBy: tokenId, orderDirection: asc) {
    id
    tokenId
    tokenURI
    mintedAt
    minter
  }
}
```

Variables: `{ "collection": "0x..." }` (collection address).

**Single token (id = collection + tokenId):**

```graphql
query Token($id: ID!) {
  token(id: $id) {
    id
    collection { id address name symbol }
    tokenId
    tokenURI
    mintedAt
    minter
  }
}
```

Token `id` is typically `{collectionAddress}-{tokenId}` (e.g. `0xabc...-1`).

---

## 7. Escrow

**Recent escrow events:**

```graphql
query RecentEscrows {
  escrows(first: 20, orderBy: blockNumber, orderDirection: desc) {
    id
    receiver
    erc20
    amount
    blockNumber
    transactionHash
  }
}
```

---

## Tips

- **Bytes** (addresses, hashes): use lowercase hex with `0x` in variables.
- **BigInt** in variables: pass as string (e.g. `"12345"`).
- **Pagination:** use `first` and optionally `skip`; for cursor-based, check if the subgraph supports `first`/`skip` or cursor args.
- **Filtering:** use `where: { field: value }` in list queries; value types must match (Bytes, BigInt, String, etc.).
- **Order:** `orderBy` and `orderDirection: asc | desc` when supported by the schema.

---

## Full schema reference

Entity and field reference for building custom queries: [references/schema.md](references/schema.md).
