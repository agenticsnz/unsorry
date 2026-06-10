# SPEC-006-B: Gate A Workflow (`.github/workflows/gate-a.yml`)

Implements: [ADR-006](../ADR-006-Gate-A-Soundness-Enforcement.md) · Status: Living · Updated: 2026-06-10

Lands with PR-9. `gate-a` joins `gate-b` as a **required status check** on `main` (ADR-005).

## Jobs

### 1. `detect` (always runs, seconds)
Determines whether the PR touches Lean-relevant paths: `library/**`, `goals/**/*.lean`, `lakefile.toml`, `lake-manifest.json`, `lean-toolchain`, `AxiomAudit/**`, `AuditFixtures/**`, `.github/workflows/gate-a.yml`. Output feeds the build job's `if:`.

**Why not `on.paths`:** a required check that is path-filtered never reports on non-matching PRs, leaving them permanently blocked on an "expected" status. The `detect`-job pattern keeps `gate-a` required while letting claims/docs/coordination PRs pass in ~30 s.

### 2. `gate-a` (the required context)
- If `detect` says non-Lean: exits green immediately (the *job* still reports, which is the point).
- Else: `leanprover/lean-action@v1` (`use-mathlib-cache: auto`, `use-github-cache: true`, `build-args: "UnsorryGoals"`) — the action installs elan per `lean-toolchain` and restores the mathlib olean cache (guaranteed published for release tags, ADR-002).
- `lake build UnsorryLibrary --wfail` — verified: exits 1 on a sorried library module, fresh **and** replayed from Lake's warning cache; exits 0 clean.
- `lake exe axiom_audit Unsorry.<each library module>` and `lake exe axiom_audit --allow-sorry goals.<each goal module>` (module lists enumerated from the tree; skip the goals call when no `.lean` goals exist). Authoritative (SPEC-006-A).
- `lake env leanchecker Unsorry.<modules>` — kernel-replays the environment (anti-tampering).
- Textual lint (belt only): fail if the PR diff under `library/` matches `\b(sorry|admit|sorryAx|native_decide|axiom|unsafe|implemented_by|extern)\b` or `set_option\s+autoImplicit\s+true`. Findings duplicate the audit; the value is a faster, louder failure.
- Footprint publishing: upload the audit JSON as artifact `axiom-report` (durable evidence) and upsert a sticky PR comment (HTML marker `<!-- axiom-report -->`) with a per-declaration footprint table.

## Required-check configuration

Branch protection on `main` requires contexts `gate-b` and `gate-a` exactly (job names are load-bearing; renaming a job without updating protection blocks all merges — ADR-005 trade-off).

## Acceptance criteria (PR-9)

1. A docs-only PR goes green in under a minute (detect short-circuit) with `gate-a` reported.
2. A PR adding a sorried theorem to `library/` fails `gate-a` (wfail layer) — exercised for real in the Stage-4 red-team (W3).
3. A clean library PR gets the axiom-report artifact and the sticky footprint comment.
4. Warm-cache wall time ≤ ~10 min.
