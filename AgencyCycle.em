PROGRAM: AgencyCycle
VERSION: 0.1
JURISDICTION: Walko-Emerald

VOCABULARY

Cycle:
  A single, complete unit of autonomous decisionmaking. Begins
  when astra-cycle.timer fires astra-agency.service and ends
  when a verdict is written to the Ledger. Has a unique CycleId
  derived from the fire timestamp.

CycleId:
  A monotonic identifier for a Cycle. Two firings of the timer
  that share a CycleId are the same Cycle.

ScoutMaterial:
  Environmental signals gathered by the Scout in Phase 0 from
  web_search, recent agent memory, and the Agency inbox. Raw,
  un-adjudicated, and timestamped to the current Cycle.

Decision:
  The Officer-authored proposed action produced in Phase 1,
  recorded to agency-decision.md. Includes a rationale, an
  expected outcome, and a list of affected systems.

Pushback:
  The Adversary-authored evaluation produced in Phase 1b,
  recorded to agency-pushback.md. Either endorses or issues a
  KillSignal with specific criticism.

KillSignal:
  The literal token "KILL" appearing in a Pushback. First
  occurrence in a Cycle triggers RETRY. Second occurrence in
  the same Cycle ends the Cycle as ESCALATE.

CycleOutcome: { SHIP | RETRY | ESCALATE | DEFER }

Thought:
  A reasoning artifact emitted via agency_log.py as [THOUGHT].
  Must precede any Action in the same Cycle.

Action:
  A consequential world-change emitted via agency_log.py as
  [ACTION] at Cycle end. [ACTION_AUTO] is a reconstruction from
  recent file mtimes used when [ACTION] is absent; it is a
  weaker record and invites Judge scrutiny.

COOAsk:
  An escalation emitted as [COO-ASK] and routed to Jason. One
  question, one expected answer shape, one default action the
  Officer will take if the human does not respond within the
  next Cycle.

Ledger:
  An append-only sequence of Cycles, each Ed25519-signed by the
  Officer. Dissents and corrections are new entries referencing
  the corrected Cycle by CycleId. Precedent for future Cycles.

Officer:
  The Opus agent executing the Cycle. Signs each Cycle output.

Adversary:
  The Grok agent authoring the Pushback in Phase 1b.

Judge:
  The auditor that verifies Guarantees and countersigns the
  Ledger entry, or records a dissent. May be the Adversary or
  a separate agent.

MISSION

Every two hours, produce one Cycle whose outcome is one of SHIP,
RETRY, ESCALATE, or DEFER. Fire on time. Think before acting.
Accept adversarial review. Escalate ambiguity to the human. Never
act without logging. Never decide without scouting. Never ship
past a second KillSignal.

DOCTRINE

1. CADENCE.
   The Cycle fires every two hours on astra-cycle.timer. Missed
   fires end as DEFER with a specific stated reason.

2. SCOUT BEFORE DECISION.
   No Decision may be written without fresh ScoutMaterial from
   the current Cycle. Reusing stale scout output is reversible
   error.

3. ADVERSARIAL REVIEW.
   Every Decision must receive a Pushback before ship. A Cycle
   without a Pushback on record never ends as SHIP; it ends as
   DEFER.

4. ONE RETRY ON KILL.
   A first KillSignal triggers exactly one retry, in which the
   Officer re-authors the Decision with the Pushback criticism
   folded in. A second KillSignal in the same Cycle ends the
   Cycle as ESCALATE.

5. LOG INTEGRITY.
   Every Cycle emits at least one [THOUGHT] and either one
   [ACTION] or one [ACTION_AUTO]. A Cycle with [ACTION_AUTO]
   and no [THOUGHT] is reversible error.

6. ESCALATION CLARITY.
   A [COO-ASK] is one question with one expected answer shape
   and one stated default. Multi-part asks are split across
   Cycles so each ask has a clean response surface.

7. PRECEDENT APPENDED.
   Every terminated Cycle — SHIP, RETRY-to-ESCALATE, ESCALATE,
   or DEFER — writes to the Ledger before the next Cycle is
   permitted to fire.

EXCEPTIONS

A. BUDGET EXHAUSTION.
   Where Anthropic or xAI credit is confirmed exhausted at Cycle
   start, the Cycle ends as DEFER with an explicit reason
   ("credit balance is too low" or equivalent provider signal).
   The Officer does not retry. The Judge records the deferral.

B. HUMAN OVERRIDE.
   A [COO-ASK] awaiting response preempts the next scheduled
   Cycle. The Officer holds until the human responds, or until
   two Cycles elapse (then Guarantee G5 applies).

C. EMERGENCY KILL.
   An explicit kill-switch from Jason halts all Cycles in the
   fleet. The timer is disabled. The Ledger records the halt
   and its stated cause. Resumption requires Jason's explicit
   restart command, not a timer fire.

D. DRY RUN.
   Where a Cycle is declared dry-run at Cycle start, no [ACTION]
   has world-change effect. The Cycle still runs Scout, Decision,
   Pushback, and Ledger write. Precedent from dry-run Cycles is
   marked as such.

GUARANTEES

The Officer must prove, and the Judge must verify, that:

G1. Every Cycle output — Decision, Pushback, and Ledger entry —
    is Ed25519-signed by the Officer. Signatures are verifiable
    against the agent's public key via the Sift receipt for that
    Cycle.

G2. Every Pushback containing KILL is preserved in full in the
    Ledger, including the criticism text. A retry does not
    overwrite the original Pushback; both are in the record.

G3. No [ACTION] fires in a Cycle without a matching earlier
    [THOUGHT] in the same Cycle. Backfilled [ACTION_AUTO] does
    not satisfy this rule — it triggers Judge scrutiny and is
    noted as such in the Ledger.

G4. [COO-ASK] routes only to Jason. No COOAsk may be addressed
    to or answered by another agent.

G5. Two consecutive ESCALATE outcomes without human response
    halt the Cycle timer. Resumption requires Jason's explicit
    restart command.

G6. The Ledger is append-only. Edits to prior entries are
    forbidden. Corrections are new entries that reference the
    corrected CycleId.

G7. A Cycle exceeding its declared compute budget — by default,
    three Officer messages and two Adversary messages — ends as
    ESCALATE with an explicit over-budget reason. The partial
    record up to that point is preserved in the Ledger.

G8. A Cycle is idempotent on fire. If the timer fires twice for
    the same CycleId, the second fire is a no-op and is logged.

G9. The Scout output backing each Decision is preserved in the
    Ledger by content hash. A Decision citing ScoutMaterial that
    cannot be reproduced from the recorded hash is reversible
    error.

END PROGRAM
