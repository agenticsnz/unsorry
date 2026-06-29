# SPEC-111-A: Proofs-Over-Time Quiet-Gap Carry-Forward

Implements: [ADR-111](../ADR-111-Proofs-Over-Time-Quiet-Gap-Carry-Forward.md) · Status: Living · Updated: 2026-06-29

ADR-111 makes the proofs-over-time chart distinguish a quiet stretch (no new proofs)
from a frozen chart by extending the x-axis right edge to the latest board-source
activity and carrying the line flat to it. This spec is the contract.

## 1. Deliverables

| # | Deliverable | Surface | CODEOWNERS? |
|---|---|---|---|
| D1 | `render_timeline_svg` extends the domain to `_latest_source_commit_z`, floored to bucket resolution, only when strictly later than the last proof bucket | `tools/leaderboard/generate.py` | **yes** (`/tools/leaderboard/` @cgbarlow) |
| D2 | Dashed carry-forward segment + edge x-tick on a gap; `· last proof <ts> UTC` subtitle (merge series) | same | **yes** |
| D3 | Tests: carry-forward on a gap; byte-identical no-gap/non-git render; existing timeline + `--check` tests stay green | `tools/leaderboard/tests/test_generate.py` | no |

## 2. Renderer (D1, D2)

- Read `edge_z = _latest_source_commit_z(root)` (already imported in the module).
- If present, floor to the series resolution — `minute=second=microsecond=0` for the
  merge (hourly) series, additionally `hour=0` for the solve (daily) fallback — and
  drop tzinfo when the series buckets are naïve (both are UTC).
- `extended` iff the floored activity is **strictly greater** than the last proof
  bucket `dts[-1]`. `domain_end = edge_dt if extended else dts[-1]`; the x-scale
  `span` is `domain_end - dts[0]`.
- When `extended`: the filled area carries flat to the right edge; a dashed grey
  (`stroke-dasharray="4 4"`, `#94a3b8`) polyline runs from the last point to the edge
  at the last point's y; an edge x-tick (`text-anchor="end"`) labels `domain_end`.
- The last-point circle, its count label, and the solid data polyline stay at the
  real last proof — the carry-forward never raises the count.
- Subtitle: `{total} cumulative kernel-verified proofs · {merged, hourly|solved, daily}`,
  plus `· last proof {%b %d %H:00} UTC` for the merge series.

## 3. Determinism (the binding constraint)

The SVG MUST remain a pure function of the corpus + git history. `_latest_source_commit_z`
bumps only on board-source merges (never the refresh's own docs-only commit, ADR-082/101),
so the extended render changes **only in lockstep with a commit that already regenerates the
board** — zero new commits, `--check`/`--write-if-stale` stay clean. Wall-clock `now` is
forbidden as an anchor.

## 4. Tests (D3)

- `test_render_timeline_svg_carries_forward_a_quiet_gap`: monkeypatch
  `generate._latest_source_commit_z` to a time several buckets after the last proof →
  assert `stroke-dasharray` present, the edge label present, count unchanged.
- `test_render_timeline_svg_no_gap_is_unextended`: `None` and an at/just-before activity
  time both yield the pre-ADR-111 byte-identical render (no `stroke-dasharray`).
- Existing `test_render_timeline_svg`, `test_render_timeline_svg_empty`,
  `test_main_write_includes_timeline_svg`, and the `--write-if-stale` suite stay green.

## 5. Out of scope

Exact-minute last-proof time (the chart is hour-bucketed; subtitle shows the bucket hour);
any guild-side rendering of the same series (separate surface).
