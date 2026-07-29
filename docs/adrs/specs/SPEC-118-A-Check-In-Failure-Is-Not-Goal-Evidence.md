# SPEC-118-A: A Check-In Failure Is Not Evidence About the Goal

Implements: [ADR-118](../ADR-118-Check-In-Failure-Is-Not-Goal-Evidence.md) · Status: Accepted · Updated: 2026-07-29

## Behaviour

When `run_proof` succeeds and `check_in_proof` fails, the cycle ends with **no `prove-failed`
event, no decomposition and no demote**. The claim is released and the outcome is reported as the
ADR-016 no-penalty class. When `run_proof` itself fails, ADR-009 decompose-on-failure is
unchanged.

## Components

### `swarm/agent.sh` — `prove_goal`

Capture the check-in outcome separately from the prove outcome. `prc` already carries
`run_proof`'s result (`0` proved, `1` failed, `2` infrastructure); add `crc` for the check-in:

```bash
if [ "$prc" -eq 0 ]; then
  if check_in_proof "$goal" "$prwt" "$camel"; then
    ok=1
  else
    crc=1
  fi
fi
```

After the existing ADR-016 `prc -eq 2` branch and **before** `emit_event prove-failed`:

```bash
if [ "$crc" -ne 0 ]; then
  log "check-in of $goal failed AFTER its proof verified locally — submission-side, not goal evidence: claim released, no penalty, no decomposition (#7159)"
  return 2
fi
```

Placement is load-bearing. Before the `prc` check it would mask a genuine infrastructure failure;
after `emit_event prove-failed` the event has already fired.

`return 2` puts the cycle in the same class `supervise` already handles for infrastructure
failures: back off, count consecutive occurrences, stop after the cap. That is the intended
behaviour for a persistent tree-level defect — surface it rather than make forward progress that
is really damage.

### `swarm/agent.sh` — `submit_pr_tree` and `queue_pr_tree`

Both discarded the validator's output. Capture and print it, bounded:

```bash
if ! gate_b_violations="$(python3 -m tools.gate_b validate "$prwt" 2>&1)"; then
  log "queued tree on $branch fails Gate B — not pushing"
  surface_gate_b_violations "$gate_b_violations"
  return 1
fi
```

New helper `surface_gate_b_violations` prints up to 20 violation lines, each prefixed, with a
`... N more` tail beyond that. It always returns 0 — diagnostics must never change control flow.

## Acceptance

1. `run_proof` succeeds, `check_in_proof` fails ⇒ `decompose_goal` is **not** called,
   `demote_goal` is **not** called, no `prove-failed` event, return code `2`.
2. `run_proof` fails ⇒ `decompose_goal` **is** called and `prove-failed` **is** emitted, exactly
   as before.
3. A Gate B rejection prints the violating rule ids and paths, not just `fails Gate B`.
4. No change to the success path, to Gate A, or to any soundness bar.

## Verification

- `test_checkin_failure_does_not_decompose` — asserts (1). Fails against the unfixed code with
  `a verified proof was decomposed on check-in failure`.
- `test_prove_failure_still_decomposes` — asserts (2), so the fix cannot disable ADR-009's real
  trigger. Passes both before and after.
- Both run inside a subshell: every stubbed name is a script-defined function, and `unset -f`
  would destroy the real definition for the rest of the suite.
- `./swarm/agent.sh --self-test` — 110/110.
