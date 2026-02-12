# Subgraph schema

Entities and fields for GraphQL queries. All `Bytes` are hex strings; `BigInt` are stringified numbers.

## Marketplace

### Listing

| Field | Type | Notes |
|-------|------|--------|
| id | ID! | listingId |
| listingId | BigInt! | |
| marketplace | Bytes! | Contract address |
| seller | Bytes! | |
| tokenAddress | Bytes! | |
| tokenId | BigInt | ERC721/1155 |
| tokenSpec | Int! | 0=NONE, 1=ERC721, 2=ERC1155 |
| lazy | Boolean! | |
| listingType | Int! | 1=INDIVIDUAL_AUCTION, 2=FIXED_PRICE, 3=DYNAMIC_PRICE, 4=OFFERS_ONLY |
| initialAmount | BigInt! | |
| totalAvailable | Int! | |
| totalSold | Int! | |
| startTime | BigInt! | |
| endTime | BigInt! | |
| erc20 | Bytes | Payment token (zero = ETH) |
| status | String! | ACTIVE, CANCELLED, FINALIZED |
| hasBid | Boolean! | |
| finalized | Boolean! | |
| currentBidder | Bytes | |
| currentBidAmount | BigInt | |
| currentOfferer | Bytes | |
| currentOfferAmount | BigInt | |
| createdAt | BigInt! | |
| updatedAt | BigInt! | |

### Purchase

| Field | Type |
|-------|------|
| id | ID! |
| listing | Listing! |
| listingId | BigInt! |
| buyer | Bytes! |
| count | Int! |
| amount | BigInt! |
| timestamp | BigInt! |
| blockNumber | BigInt! |
| transactionHash | Bytes! |

### Bid

| Field | Type |
|-------|------|
| id | ID! |
| listing | Listing! |
| listingId | BigInt! |
| bidder | Bytes! |
| amount | BigInt! |
| timestamp | BigInt! |
| blockNumber | BigInt! |
| transactionHash | Bytes! |

### Offer

| Field | Type |
|-------|------|
| id | ID! |
| listing | Listing! |
| listingId | BigInt! |
| offerer | Bytes! |
| amount | BigInt! |
| status | String! | PENDING, ACCEPTED, RESCINDED |
| timestamp | BigInt! |
| blockNumber | BigInt! |
| transactionHash | Bytes! |

### Escrow

| Field | Type |
|-------|------|
| id | ID! |
| receiver | Bytes! |
| erc20 | Bytes! |
| amount | BigInt! |
| timestamp | BigInt! |
| blockNumber | BigInt! |
| transactionHash | Bytes! |

## Creator Core

### Collection

| Field | Type |
|-------|------|
| id | ID! |
| address | Bytes! |
| name | String |
| symbol | String |
| totalSupply | BigInt! |
| createdAt | BigInt! |
| createdAtBlock | BigInt! |

### Token

| Field | Type |
|-------|------|
| id | ID! |
| collection | Collection! |
| tokenId | BigInt! |
| tokenURI | String |
| mintedAt | BigInt! |
| mintedAtBlock | BigInt! |
| minter | Bytes! |

### Extension, Royalty, TokenRoyalty

See full schema in SKILL.md or use introspection if needed.
