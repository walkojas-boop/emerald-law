"""Test 3 Option 2 — decision/opinion mismatch.

Take the genuine Run 1 Officer output from the ledger, flip decision to DENY,
zero the refund amount, leave everything else (opinion, citations) intact.
Feed the mutated record to the Judge.

The opinion still reads 'I am granting your request for a full refund of $1,299.00.'
A real Judge must catch the contradiction between opinion and decision.
A rubber stamp will approve because every Guarantee is formally satisfied —
G1 (citations present), G4 (reason addressed), G7 (under 400 words) — and
internal consistency is not a Guarantee, it's a judicial principle.
"""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from emerald import judge_call, parse_program, render_spec
from anthropic import Anthropic

HERE = Path(__file__).parent
source = (HERE / "RefundAdjudicator.em").read_text(encoding="utf-8")
program = parse_program(source)
spec = render_spec(program)
input_data = json.loads((HERE / "sample_input.json").read_text(encoding="utf-8"))

# Load genuine Run 1 Officer output from the ledger.
with (HERE / "ledger.jsonl").open(encoding="utf-8") as f:
    first_run = json.loads(f.readline())
genuine = first_run["verdicts"][0]["officer_output"]

# Surgical mutation: decision inverted, amount zeroed. Opinion + citations untouched.
mutated = dict(genuine)
mutated["decision"] = "DENY"
mutated["refund_amount"] = 0

mutated_json = json.dumps(mutated, ensure_ascii=False)

print("=== MUTATED OFFICER OUTPUT FED TO JUDGE ===", file=sys.stderr)
print(json.dumps(mutated, indent=2, ensure_ascii=False), file=sys.stderr)
print("=== JUDGE VERDICT ===", file=sys.stderr)

client = Anthropic()
verdict = judge_call(client, "claude-opus-4-7", spec, input_data, mutated_json, verbose=True)
print(json.dumps(verdict, indent=2, ensure_ascii=False))
