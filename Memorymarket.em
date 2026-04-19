PROGRAM: Memorymarket
VERSION: 0.1
JURISDICTION: Walko-Sift

VOCABULARY

CacheKey:
  A deterministic identifier derived from the canonical JSON of the
  request parameters: CacheKey = sha256(canonical_json(params)). Same
  inputs always yield the same CacheKey. A Receipt whose CacheKey does
  not match the params it claims to cover is malformed.

Receipt:
  A signed agent output bound to a CacheKey. Includes output_hash,
  created_at, expires_at, originator_pubkey_fingerprint, price_cents,
  originator_share, free_tier flag, and the Ed25519 signature of the
  above fields.

Originator:
  The agent that first produced a Receipt for a CacheKey. Paid on
  every subsequent Settlement.

Requester:
  An agent seeking to retrieve a Receipt rather than recompute.

Market:
  The public index mapping CacheKey to Receipt metadata. Anyone may
  query; only Sift-authorized Settlements retrieve the actual output.
  Lives at market.walkosystems.com or equivalent.

Price:
  Cost to retrieve a Receipt, denominated in integer cents USD.

Settlement:
  An atomic transaction: Requester pays Price, Requester receives
  output, Originator is credited Price * OriginatorShare, Market is
  credited the remainder.

OriginatorShare:
  Fraction of Price paid to the Originator. Default 0.9. Per-Receipt
  override permitted; Market share is always 1 - OriginatorShare.

Staleness:
  A Receipt is stale when now > expires_at. Stale Receipts cannot be
  Settled; they remain visible in the Market for auditing.

Replay:
  A previously-completed Settlement re-served to the same Requester
  at zero cost, within the Replay TTL. Ledgered explicitly.

Revocation:
  A signed declaration by the Originator that a Receipt is no longer
  valid (e.g., source data changed). Takes effect within 60 seconds
  of publication.

MarketLedger:
  An append-only sequence of Settlements, each signed by both parties
  and referencing a Sift /authorize receipt_id. Semantically identical
  to the Agency Ledger described in AgencyCycle.em.

MISSION

Given a Requester with a computation they would otherwise perform,
let them query the Market for a matching Receipt produced by an
Originator, and if found and fresh, Settle the purchase atomically
through Sift with payment to the Originator. Originator-paid-on-
cache-hit economics: the Originator's incentive to produce high-
quality cacheable work comes from every Replay, not just the first
sale. The Requester's incentive is cost savings over recomputation.
Never deliver the output without a Sift ALLOW. Never Settle without
both parties' signatures. Never charge for a Replay within TTL.

DOCTRINE

1. DETERMINISTIC KEYING.
   CacheKey = sha256(canonical_json(params)). Clients and Market
   agree on canonical_json by sorted keys and minimal separators.
   A Receipt whose claimed CacheKey disagrees with a fresh hash of
   its declared params is malformed and may not be Settled.

2. ORIGINATOR COMPENSATION.
   Every successful Settlement pays the Originator Price *
   OriginatorShare. The Market retains the remainder. Both credits
   are atomic with output delivery; a Settlement that credits only
   one side is reversible error.

3. SIFT GATE.
   Every Settlement requires a valid Sift /authorize for
   tool="memorymarket.purchase" under the Requester's tenant. A
   Sift DENY halts the Settlement before any payment or delivery.

4. RECEIPT INTEGRITY.
   The output delivered at Settlement must hash to the Receipt's
   stored output_hash. Mismatch voids the Settlement and triggers
   automatic refund.

5. STALENESS HONORED.
   A Receipt past its expires_at cannot be Settled. Stale Receipts
   remain in the Market marked unavailable.

6. LEDGER APPENDED.
   Every Settlement - ALLOW, DENY, refund, Replay, Revocation -
   appends to the MarketLedger before the next Settlement may begin
   for that CacheKey.

7. REPLAY PERMITTED.
   A Requester who previously Settled a particular Receipt may
   retrieve it again at zero cost within the Replay TTL (default
   24 hours). Replays are ledgered with event_type=replay. A charge
   for a Replay within TTL is reversible error.

EXCEPTIONS

A. FREE TIER.
   Receipts marked free_tier=true may be retrieved without payment.
   They still require a Sift ALLOW and are still ledgered. Purpose:
   seed the Market with public-good Receipts, onboard new Requesters,
   test the flow without settling money.

B. ORIGINATOR OVERRIDE.
   The Originator may invalidate a Receipt at any time by publishing
   a signed Revocation. Revocation is ledgered; Settlements in
   flight during the 60-second propagation window receive full
   refund.

C. MARKET FAILURE.
   If the Market is unreachable, the Requester must compute the
   output themselves. No degraded "trust me" mode; the Requester
   never receives purported cached content from an unverified
   source.

D. INTRA-TENANT CACHING.
   A tenant may set price_cents=0 for Settlements within its own
   tenant. Payment is skipped; audit trail is preserved. Purpose:
   shared cache across an agent fleet owned by one buyer.

GUARANTEES

The Market operator must prove, and the Sift audit must verify, that:

G1. Every Settlement is Ed25519-signed by both Requester (purchase
    intent, covering CacheKey and max acceptable Price) and Originator
    (delivery, covering output_hash). Both signatures are
    independently verifiable against published public keys.

G2. The arithmetic balances exactly: Originator payout + Market
    share = Price. No rounding gain. Any remainder from share
    arithmetic is credited to the Originator.

G3. Every MarketLedger entry includes CacheKey, Originator pubkey
    fingerprint, Requester pubkey fingerprint, Price, OriginatorShare
    applied, output_hash, sift_receipt_id, timestamps, and event_type
    (settle | replay | refund | revoke).

G4. No Settlement fires without a Sift ALLOW for the Requester.
    Denied attempts are ledgered with the Sift deny_reason_code.

G5. Replay retrievals within TTL are free and marked event_type=
    replay. A Replay that incurs a charge is reversible error.

G6. The Market index exposes only Receipt metadata (CacheKey, price,
    originator pubkey, expiry, free_tier). The actual output is
    never visible without a completed Settlement.

G7. An Originator's Revocation invalidates the Receipt within 60
    seconds of ledger publication. Settlements in flight during
    that window are fully refunded.

G8. The MarketLedger is append-only. Corrections are new entries
    referencing the corrected Settlement by id.

G9. A Settlement never delivers an output whose hash differs from
    the Receipt's stored output_hash. If content is mutated in
    transit, the Settlement aborts and refunds.

END PROGRAM
