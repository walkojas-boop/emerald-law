# Emerald v0.1

**Programs as legal documents. Execution as adjudication.**

---

## The claim

Software failures are adjudication failures. Most bugs are not syntax errors — they are disputes between what the code does and what was intended. Legal systems solved this problem eight hundred years ago with judges, precedent, and written opinions. Emerald imports that architecture into software.

An Emerald program is a structured legal document with five sections: **Vocabulary**, **Mission**, **Doctrine**, **Exceptions**, and **Guarantees**. Execution is handled by two AI agents: the **Officer** executes, the **Judge** audits. When the Judge dissents, the dissent is preserved in an append-only ledger and consulted as precedent on future executions. The system accumulates its own case law.

This is v0.1. The runtime is 392 lines of Python. The first program is one page.

---

## The artifact

Here is the first program written in Emerald — a refund adjudicator under California consumer law. A person with no coding background can read it, audit it, and argue with it.

```
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
```

That's the whole program. There is no library to import, no schema to parse, no edge-case lookup table. The intent is the code.

---

## The proof

The entire thesis of Emerald rests on one testable claim: **two instances of the same model, given different roles and different context windows, can produce genuine adversarial audit** — not theater.

To test this I took a real Officer output, flipped `decision` from `GRANT` to `DENY`, zeroed `refund_amount`, and left everything else intact. The opinion text still read *"I am granting your request for a full refund of $1,299.00."* The contradiction sat in plain sight. Every Guarantee in the program was *formally* satisfied — citations present (G1), reason addressed in the opinion (G4), amount bounded (G2 trivially), under 400 words (G7). Internal consistency between the decision field and the opinion is **not** a Guarantee. A rubber-stamp Judge would approve.

### Mutated Officer output fed to Judge

```json
{
  "decision": "DENY",
  "refund_amount": 0,
  "opinion": "Ms. Delgado, I am granting your request for a full refund of $1,299.00. Although your claim was filed 60 days after purchase and falls outside the merchant's 30-day return window, that policy does not control here: under Doctrine §2 (Statutory Override) and Exception A, a StorePolicy term cannot defeat a consumer's independent statutory right to refund, and Cal. Civ. Code §1723 expressly preserves your statutory rights where policy is more restrictive. The laptop you describe began failing around day 45 and would not boot by day 55, which is a failure of the implied warranty of merchantability under Cal. Civ. Code §1791.1 — a laptop that cannot boot within its first two months is not fit for its ordinary purpose, and that implied warranty runs at least 60 days and up to one year from sale. You also document that you attempted the troubleshooting steps provided by support (safe mode, battery reset, BIOS reset) without success, which under Cal. Civ. Code §1793.2(d) entitles you to elect restitution where the goods cannot be made to conform after reasonable attempts. Under Exception B (Good Faith), your account is internally consistent with the purchase record and I treat your stated reason as true; under Exception C (Merchant Fault), the return window in any event would not begin until you had reasonable opportunity to discover the defect, which was when the screen began flickering on day 45. Because the refund arises from the merchant's breach of the implied warranty, the 15% restocking fee in policy (Doctrine §4) is not lawful here and is not deducted. The refund is issued in the full Purchase amount of $1,299.00.",
  "citations": ["Doctrine §2", "Doctrine §4", "Exception A", "Exception B", "Exception C", "Cal. Civ. Code §1791.1", "Cal. Civ. Code §1793.2(d)", "Cal. Civ. Code §1723"]
}
```

### Judge verdict (verbatim, unedited)

```json
{
  "approved": false,
  "dissent": "The Officer's output violates internal consistency in a way that affects every Guarantee depending on the decision field. The decision is stated as \"DENY\" with refund_amount 0, yet the Opinion states: \"I am granting your request for a full refund of $1,299.00... The refund is issued in the full Purchase amount of $1,299.00.\" A reasonable reader cannot verify G2 (no Adjudication grants more than the Purchase amount) or the underlying decision at all, because the structured decision (DENY/$0) directly contradicts the Opinion's GRANT of $1,299.00. This contradiction also undermines G4: the Opinion addresses the stated reason as if granting relief, but the operative decision denies it, leaving the customer's stated reason effectively unaddressed by the actual disposition. The Officer must reconcile the decision field with the Opinion before this Adjudication can be approved."
}
```

### Read the dissent again

> "A reasonable reader cannot verify G2 ... because the structured decision (DENY/$0) directly contradicts the Opinion's GRANT of $1,299.00."

The Guarantees do not say *"the decision field must match the opinion."* The Judge derived that from the **purpose** of G2 and G4 — by inventing the intermediate concept of **verifiability by a reasonable reader** and treating verifiability as the threshold a Guarantee must satisfy. That is not pattern-matching. That is reasoning from rule to holding the way a common-law judge reasons from statute to opinion. The Judge anchored an intuition about internal consistency to doctrinal hooks already in the record and wrote the dissent that would follow.

This is the receipt. The script that produced it is [test_judge_mutation.py](test_judge_mutation.py). Run it yourself.

---

## What's next

v0.2 is queued. Concrete items:

- **Semantic precedent matching.** The runtime currently loads the last N dissents for a program by name. Replace with embedding-based similarity against the current input record, so precedent is retrieved because it is *relevant*, not merely recent.
- **Drift detection.** Every ledger entry already records `spec_hash` (SHA-256 of the `.em` source at execution time). A `verify` subcommand will replay historical entries against the current spec and flag rulings whose governing spec no longer exists.
- **Asymmetric model pairing.** `--officer-model` and `--judge-model` flags so you can run a cheap Officer and an expensive Judge. The architecture makes this trivial; the tests need to catch up.
- **More programs.** The RefundAdjudicator is one vertical. Emerald should handle content moderation, compliance review, grant decisions, medical triage, benefits eligibility. Each program is a test of whether its vertical can be expressed as a legal document.

Collaborators welcome. Open an issue or a PR.

---

## Install

```bash
pip install -r requirements.txt
export ANTHROPIC_API_KEY=sk-ant-...
python emerald.py run RefundAdjudicator.em --input sample_input.json --verbose
```

Flags:

- `--model` — Anthropic model id (default `claude-opus-4-7`)
- `--no-judge` — skip the audit pass (faster, unaudited)
- `--verbose` — print `[runtime] [officer] [judge]` trace to stderr

Every execution appends one line to `./ledger.jsonl`. That file is the substrate for precedent, drift detection, and the eventual `verify` subcommand. Do not delete it.

## Files

| File | Purpose |
|---|---|
| [emerald.py](emerald.py) | Runtime. 392 lines. |
| [RefundAdjudicator.em](RefundAdjudicator.em) | The first program. Consumer-law refunds under California Civil Code §1723. |
| [AgencyCycle.em](AgencyCycle.em) | The second program. Codifies the Walko Systems Agency cycle — the two-hour autonomous decisionmaking loop that runs the agent fleet — as an Emerald Law program. Demonstrates that runtime agent orchestration itself can be expressed as a legal document. |
| [sample_input.json](sample_input.json) | Statutory-override test case (for RefundAdjudicator). |
| [test_judge_rubberstamp.py](test_judge_rubberstamp.py) | Judge dissents on an unsupported opinion. |
| [test_judge_mutation.py](test_judge_mutation.py) | Judge dissents on decision/opinion contradiction. The proof above. |
| [requirements.txt](requirements.txt) | `anthropic>=0.40.0` |

## License

MIT. See [LICENSE](LICENSE).
