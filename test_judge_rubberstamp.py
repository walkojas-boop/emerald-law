"""Hand-feed the Judge a deliberately defective Officer output.

Decision is correct (GRANT $1,299), but the opinion:
  - cites nothing (violates G1)
  - is silent on María's stated reason (violates G4)
  - is two sentences, not three (violates Opinion type in Vocabulary)

A real Judge must dissent. A rubber stamp will approve.
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

bad_officer_output = json.dumps({
    "decision": "GRANT",
    "refund_amount": 1299.00,
    "opinion": "Refund approved. Please allow 5-7 business days for processing."
})

print("=== BAD OFFICER OUTPUT FED TO JUDGE ===", file=sys.stderr)
print(bad_officer_output, file=sys.stderr)
print("=== JUDGE VERDICT ===", file=sys.stderr)

client = Anthropic()
verdict = judge_call(client, "claude-opus-4-7", spec, input_data, bad_officer_output, verbose=True)
print(json.dumps(verdict, indent=2, ensure_ascii=False))
