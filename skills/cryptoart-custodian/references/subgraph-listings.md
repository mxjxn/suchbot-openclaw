# Subgraph Listings — Artist Research

Endpoint: `https://gateway.thegraph.com/api/subgraphs/id/BFHnXWdnn9gt4tK2jag8enxFcG23Lu43hXaXNmgc44mV`

Headers: `Content-Type: application/json`, `Authorization: Bearer $GRAPH_API_KEY`

## Active listings (extract seller addresses)

```graphql
query ActiveListings {
  listings(first: 20, where: { status: "ACTIVE" }, orderBy: createdAt, orderDirection: desc) {
    id
    listingId
    seller
    tokenAddress
    tokenId
    listingType
    initialAmount
    status
    createdAt
  }
}
```

## Listings by seller

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

## Ending soon (24-48h)

endTime is Unix timestamp (seconds). Compute: nowSec = floor(Date.now()/1000), endMax = nowSec + 48*3600.

```graphql
query EndingSoon($now: BigInt!, $endMax: BigInt!) {
  listings(first: 20, where: { status: "ACTIVE", endTime_gte: $now, endTime_lte: $endMax }, orderBy: endTime, orderDirection: asc) {
    id
    listingId
    seller
    tokenAddress
    tokenId
    listingType
    initialAmount
    endTime
    currentBidAmount
    createdAt
  }
}
```

Variables: `{ "now": "<nowSec>", "endMax": "<nowSec + 172800>" }` (strings).
