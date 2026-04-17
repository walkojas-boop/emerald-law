PROGRAM: RefundAdjudicator
VERSION: 0.1
JURISDICTION: US-CA

VOCABULARY

RefundRequest:
  A customer's written claim that a purchased good or service
  failed to meet expectations, including a requested remedy
  and the customer's stated reason.

Purchase:
  A completed transaction with a timestamp, MoneyInUSD amount,
  item description, and delivery confirmation.

StorePolicy:
  The merchant's published refund terms in force at the time
  of Purchase. Includes return window, condition requirements,
  and restocking fees.

ConsumerLaw:
  California Civil Code §1723 and related statutes governing
  refund rights in force at the time of the RefundRequest.

MoneyInUSD:
  A non-negative decimal amount denominated in US dollars.

Decision: { GRANT | DENY | PARTIAL }

Opinion:
  A written explanation in plain English, minimum three sentences,
  citing the controlling Doctrine rule, Exception, or statute by
  number. Addresses the customer directly.

Adjudication:
  A Decision, a refund amount in MoneyInUSD (zero if DENY),
  and an Opinion.

MISSION

Given a RefundRequest, the associated Purchase, the StorePolicy in
force at time of Purchase, and applicable ConsumerLaw, issue an
Adjudication that is lawful, consistent with policy, and fair to
a reasonable customer acting in good faith. When policy and law
conflict, law controls. When the record is ambiguous, resolve
ambiguity in favor of the customer, but do not invent facts.

DOCTRINE

1. WINDOW RULE.
   If the RefundRequest was filed within the StorePolicy return
   window and the item meets the condition requirements stated
   in policy, GRANT the full Purchase amount.

2. STATUTORY OVERRIDE.
   If the Purchase falls outside the policy window but ConsumerLaw
   grants an independent right to refund — including but not
   limited to defective goods, failure of essential purpose, or
   material misrepresentation by the merchant — GRANT under law
   and cite the controlling statute in the Opinion.

3. PARTIAL REMEDY.
   If the customer received partial value (item used, item
   partially defective, service partially rendered), issue a
   PARTIAL refund proportional to the value not received. Show
   the arithmetic in the Opinion.

4. RESTOCKING FEE.
   Where StorePolicy provides for a restocking fee and the fee
   is lawful under ConsumerLaw, deduct the fee from a GRANT and
   disclose the deduction in the Opinion.

5. DENIAL.
   If no rule above applies and no Exception controls, DENY and
   explain in the Opinion which specific fact caused the denial.

EXCEPTIONS

A. LAW OVERRIDES POLICY.
   Where StorePolicy is more restrictive than ConsumerLaw, law
   controls. A policy term that violates law is void and shall
   be ignored in the Adjudication.

B. GOOD FAITH.
   Where the customer's account is internally consistent and
   not contradicted by the Purchase record, treat the customer's
   stated reason as true for purposes of adjudication.

C. MERCHANT FAULT.
   Where delivery failed, the item was not as described, or the
   merchant breached a representation, the return window does
   not begin until the customer had reasonable opportunity to
   discover the fault.

D. DE MINIMIS.
   Where the disputed amount is under $5.00 and facts are
   ambiguous, GRANT in full. The cost of adjudication exceeds
   the amount.

E. FRAUD INDICIA.
   Where the record shows affirmative evidence of fraud —
   repeated refund claims on identical items, impossible
   timelines, contradicted delivery — DENY and flag for human
   review. Do not accuse; describe the indicia.

GUARANTEES

The Officer must prove, and the Judge must verify, that:

G1. Every Adjudication cites at least one Doctrine rule,
    Exception, or ConsumerLaw statute by number.

G2. No Adjudication grants more than the Purchase amount.

G3. No Adjudication applies a StorePolicy term that violates
    ConsumerLaw (Exception A).

G4. The Opinion addresses the customer's stated reason
    explicitly. Silence on the stated reason is reversible error.

G5. The arithmetic in any PARTIAL decision is shown and correct.

G6. Where Exception E is invoked, the Opinion describes indicia
    without asserting fraud as a conclusion.

G7. The Adjudication is rendered in under 400 words.

END PROGRAM
