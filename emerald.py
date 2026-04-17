#!/usr/bin/env python3
"""Emerald v0.1 runtime — execute legal-document programs via paired AI agents.

Officer proposes. Judge audits. Dissents become precedent. Ledger is append-only.

    python emerald.py run program.em --input data.json [flags]

Requires ANTHROPIC_API_KEY in the environment.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from anthropic import Anthropic

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

LEDGER_PATH = Path("./ledger.jsonl")
DEFAULT_MODEL = "claude-opus-4-7"
MAX_PRECEDENTS = 5
MAX_TOKENS = 2048
MAX_ATTEMPTS = 2  # Officer attempt + one retry on dissent
SECTIONS = ("VOCABULARY", "MISSION", "DOCTRINE", "EXCEPTIONS", "GUARANTEES")

# ---------------------------------------------------------------------------
# Parser — lenient, reads structured prose, tolerates markdown headers
# ---------------------------------------------------------------------------

_HEADER_RE = re.compile(
    r"^(?:#+\s*)?(VOCABULARY|MISSION|DOCTRINE|EXCEPTIONS|GUARANTEES|END\s+PROGRAM)\s*$",
    re.MULTILINE,
)
_META_RE = re.compile(r"^(PROGRAM|VERSION|JURISDICTION):\s*(.+?)\s*$", re.MULTILINE)


def parse_program(source: str) -> dict[str, Any]:
    """Parse an .em file into metadata + five sections."""
    meta = {m.group(1).lower(): m.group(2).strip() for m in _META_RE.finditer(source)}
    sections: dict[str, str] = {s.lower(): "" for s in SECTIONS}

    matches = list(_HEADER_RE.finditer(source))
    for i, m in enumerate(matches):
        name = re.sub(r"\s+", " ", m.group(1)).upper()
        if name == "END PROGRAM":
            break
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(source)
        sections[name.lower()] = source[start:end].strip()

    return {
        "name": meta.get("program", "Unnamed"),
        "version": meta.get("version", "0"),
        "jurisdiction": meta.get("jurisdiction", ""),
        **sections,
    }


def render_spec(program: dict[str, Any]) -> str:
    """Render the parsed program back to canonical spec text for the agents."""
    parts = [
        f"PROGRAM: {program['name']}",
        f"VERSION: {program['version']}",
        f"JURISDICTION: {program['jurisdiction']}",
        "",
    ]
    for section in SECTIONS:
        parts.append(f"## {section}")
        parts.append(program[section.lower()] or "(none)")
        parts.append("")
    return "\n".join(parts)


# ---------------------------------------------------------------------------
# Ledger — append-only JSONL, source of truth for precedent
# ---------------------------------------------------------------------------

def append_ledger(entry: dict[str, Any]) -> None:
    with LEDGER_PATH.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def load_precedents(program_name: str, limit: int = MAX_PRECEDENTS) -> list[dict]:
    if not LEDGER_PATH.exists():
        return []
    dissents: list[dict] = []
    with LEDGER_PATH.open(encoding="utf-8") as f:
        for line in f:
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                continue
            if entry.get("program") != program_name:
                continue
            for v in entry.get("verdicts", []):
                if v.get("dissent"):
                    dissents.append({
                        "timestamp": entry.get("timestamp"),
                        "input_summary": _summarize(entry.get("input")),
                        "rejected_output": v.get("officer_output"),
                        "dissent": v.get("dissent"),
                    })
    return dissents[-limit:]


def _summarize(obj: Any, cap: int = 400) -> str:
    s = json.dumps(obj, ensure_ascii=False)
    return s if len(s) <= cap else s[:cap] + "…"


# ---------------------------------------------------------------------------
# Model output extraction — tolerant JSON parser
# ---------------------------------------------------------------------------

_FENCE_RE = re.compile(r"^```(?:json)?\s*|\s*```\s*$", re.MULTILINE)


def extract_json(text: str) -> dict[str, Any]:
    cleaned = _FENCE_RE.sub("", text.strip())
    start = cleaned.find("{")
    end = cleaned.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise ValueError(f"No JSON object found in model output:\n{text[:400]}")
    return json.loads(cleaned[start : end + 1])


def _message_text(resp) -> str:
    return "".join(
        b.text for b in resp.content if getattr(b, "type", "") == "text"
    ).strip()


# ---------------------------------------------------------------------------
# Officer — proposes an adjudication
# ---------------------------------------------------------------------------

_OFFICER_SUFFIX = """

## ROLE
You are the Officer. Execute the MISSION given the input record. Apply DOCTRINE
in order, honor EXCEPTIONS where they control, and satisfy every GUARANTEE.
Your output will be audited by a Judge.

## OUTPUT FORMAT
Respond with a single JSON object and nothing else — no prose, no markdown fences.
Required keys:
  decision       string, one of: GRANT | DENY | PARTIAL
  refund_amount  number, USD. Zero if DENY.
  opinion        string, plain-English opinion addressed to the customer,
                 at least three sentences, citing every Doctrine rule,
                 Exception, or statute relied upon by its identifier.
  citations      array of strings, the rule/exception/statute identifiers
                 cited in the opinion (e.g. "Doctrine §2", "Exception C",
                 "Cal. Civ. Code §1791.1").
"""


def officer_call(
    client: Anthropic,
    model: str,
    spec: str,
    input_data: Any,
    precedents: list[dict],
    prior_dissent: str | None,
    verbose: bool,
) -> tuple[dict, str]:
    system = spec + _OFFICER_SUFFIX
    if precedents:
        system += "\n## PRIOR DISSENTS\n"
        system += (
            "The following dissents have been issued by the Judge on prior "
            "executions of this program. They have precedential weight — do not "
            "repeat these errors.\n\n"
        )
        for i, p in enumerate(precedents, 1):
            system += (
                f"### Precedent {i} — {p['timestamp']}\n"
                f"Input (truncated): {p['input_summary']}\n"
                f"Rejected output: {json.dumps(p['rejected_output'], ensure_ascii=False)[:400]}\n"
                f"Judge dissent: {p['dissent']}\n\n"
            )

    user = f"INPUT RECORD:\n```json\n{json.dumps(input_data, indent=2, ensure_ascii=False)}\n```"
    if prior_dissent:
        user += (
            "\n\n## YOUR PRIOR ATTEMPT WAS REJECTED\n"
            f"Judge dissent:\n{prior_dissent}\n\n"
            "Issue a new Adjudication that resolves the dissent. "
            "Do not ignore or argue with the Judge — correct the defect."
        )

    if verbose:
        print(
            f"[officer] model={model} precedents={len(precedents)} "
            f"retry={'yes' if prior_dissent else 'no'}",
            file=sys.stderr,
        )

    resp = client.messages.create(
        model=model,
        max_tokens=MAX_TOKENS,
        system=system,
        messages=[{"role": "user", "content": user}],
    )
    text = _message_text(resp)
    return extract_json(text), text


# ---------------------------------------------------------------------------
# Judge — audits the Officer's output against the Guarantees
# ---------------------------------------------------------------------------

_JUDGE_SUFFIX = """

## ROLE
You are the Judge. Audit the Officer's adjudication against the GUARANTEES.
Approve only if every Guarantee is met. Otherwise dissent — identify the
specific Guarantee violated (by identifier, e.g. G4) and quote the offending
portion of the Officer's output.

Be strict but not pedantic: a Guarantee is met if a reasonable reader could
verify it from the Officer's output. Do not manufacture grounds for dissent.

## OUTPUT FORMAT
Respond with a single JSON object and nothing else:
  approved  boolean
  dissent   string | null   null when approved, otherwise a written dissent
                            citing the violated Guarantee
"""


def judge_call(
    client: Anthropic,
    model: str,
    spec: str,
    input_data: Any,
    officer_text: str,
    verbose: bool,
) -> dict:
    system = spec + _JUDGE_SUFFIX
    user = (
        f"INPUT RECORD:\n```json\n{json.dumps(input_data, indent=2, ensure_ascii=False)}\n```"
        f"\n\nOFFICER OUTPUT:\n{officer_text}"
    )
    if verbose:
        print(f"[judge] model={model}", file=sys.stderr)

    resp = client.messages.create(
        model=model,
        max_tokens=MAX_TOKENS,
        system=system,
        messages=[{"role": "user", "content": user}],
    )
    return extract_json(_message_text(resp))


# ---------------------------------------------------------------------------
# Execution loop
# ---------------------------------------------------------------------------

def run(program_path: str, input_path: str, model: str, no_judge: bool, verbose: bool) -> int:
    source = Path(program_path).read_text(encoding="utf-8")
    spec_hash = hashlib.sha256(source.encode("utf-8")).hexdigest()
    program = parse_program(source)
    input_data = json.loads(Path(input_path).read_text(encoding="utf-8"))
    spec = render_spec(program)

    client = Anthropic()
    precedents = load_precedents(program["name"])

    if verbose:
        print(
            f"[runtime] program={program['name']} v{program['version']} "
            f"jurisdiction={program['jurisdiction']} precedents={len(precedents)}",
            file=sys.stderr,
        )

    verdicts: list[dict] = []
    final: dict | None = None
    dissent_for_retry: str | None = None

    for attempt in range(1, MAX_ATTEMPTS + 1):
        officer_out, officer_text = officer_call(
            client, model, spec, input_data, precedents, dissent_for_retry, verbose
        )

        if no_judge:
            verdicts.append({
                "attempt": attempt,
                "officer_output": officer_out,
                "approved": None,
                "dissent": None,
                "note": "judge skipped (--no-judge)",
            })
            final = officer_out
            break

        verdict = judge_call(client, model, spec, input_data, officer_text, verbose)
        approved = bool(verdict.get("approved"))
        dissent = verdict.get("dissent")

        verdicts.append({
            "attempt": attempt,
            "officer_output": officer_out,
            "approved": approved,
            "dissent": dissent,
        })

        if approved:
            final = officer_out
            break

        if verbose:
            print(f"[judge] dissent on attempt {attempt}: {dissent}", file=sys.stderr)

        if attempt == MAX_ATTEMPTS:
            final = {
                "decision": "DEFERRED",
                "refund_amount": 0,
                "opinion": (
                    "The Judge twice rejected the Officer's adjudication. "
                    "This matter is deferred to human review. Dissent below."
                ),
                "citations": [],
                "judge_dissent": dissent,
                "last_officer_output": officer_out,
            }
            break

        dissent_for_retry = dissent

    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "program": program["name"],
        "version": program["version"],
        "spec_hash": spec_hash,
        "jurisdiction": program["jurisdiction"],
        "model": model,
        "input": input_data,
        "verdicts": verdicts,
        "final": final,
    }
    append_ledger(entry)
    print(json.dumps(final, indent=2, ensure_ascii=False))

    last = verdicts[-1] if verdicts else {}
    return 0 if last.get("approved") in (True, None) else 2


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main() -> int:
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8")
        except Exception:
            pass

    ap = argparse.ArgumentParser(prog="emerald", description="Emerald v0.1 runtime")
    sub = ap.add_subparsers(dest="cmd", required=True)

    r = sub.add_parser("run", help="Execute an Emerald program")
    r.add_argument("program", help="Path to .em program file")
    r.add_argument("--input", required=True, help="Path to input JSON")
    r.add_argument("--model", default=DEFAULT_MODEL,
                   help=f"Anthropic model id (default {DEFAULT_MODEL})")
    r.add_argument("--no-judge", action="store_true",
                   help="Skip the Judge audit pass (faster, unaudited)")
    r.add_argument("--verbose", action="store_true")

    args = ap.parse_args()
    if args.cmd == "run":
        if not os.environ.get("ANTHROPIC_API_KEY"):
            print("error: ANTHROPIC_API_KEY not set in environment", file=sys.stderr)
            return 2
        return run(args.program, args.input, args.model, args.no_judge, args.verbose)
    return 1


if __name__ == "__main__":
    sys.exit(main())
