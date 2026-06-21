# SPEC-006-B: Gate A Workflow (`.github/workflows/gate-a.yml`)

Implements: [ADR-006](../ADR-006-Gate-A-Soundness-Enforcement.md) · Status: Living · Updated: 2026-06-14

Lands with PR-9. `gate-a` joins `gate-b` as a **required status check** on `main` (ADR-005).

## Jobs

### 1. `detect` (always runs, seconds)
Determines whether the PR touches Lean-relevant paths: `library/**`, `goals/**/*.lean`, `lakefile.toml`, `lake-manifest.json`, `lean-toolchain`, `AxiomAudit/**`, `AuditFixtures/**`, `.github/workflows/gate-a.yml`. Output feeds the build job's `if:`.

**Why not `on.paths`:** a required check that is path-filtered never reports on non-matching PRs, leaving them permanently blocked on an "expected" status. The `detect`-job pattern keeps `gate-a` required while letting claims/docs/coordination PRs pass in ~30 s.

### 2. Heavy jobs and aggregate `gate-a` (the required context)
- `gate_a_prepare`, `gate_a_audit`, and `gate_a_replay` run on role-specific Namespace managed (ephemeral) runners (ADR-058): **`namespace-profile-unsorry-prepare`** for cache warming, goal builds, statement bindings, and cheap checks; **`namespace-profile-unsorry-audit`** for serial `axiom_audit`; and **`namespace-profile-unsorry-replay`** for leanchecker replay. Archive validation also uses `namespace-profile-unsorry-prepare` because archive replay was removed by ADR-048. The replay tool still decides whether scope is incremental or full (`forces_full_replay`: `lean-toolchain`, `lakefile*`, `lake-manifest.json`), but runner selection is by job role so capacity can be adjusted independently. The `leanchecker` replay stays **serial** and the swap-headroom step is **best-effort** (Namespace disallows `swapon`; the replay profile provides RAM, with `UNSORRY_REPLAY_CHUNK` as the fallback path). Profile-backed keeps the runner ephemeral (no self-hosted tampering surface). `detect` and the final aggregate `gate-a` job stay on free GitHub-hosted runners.
- If `detect` says non-Lean: the heavy jobs are skipped and the aggregate `gate-a` job exits green immediately. This keeps the required context stable without spending a Namespace runner.
- `gate_a_prepare` restores/builds with `leanprover/lean-action@v1` (`use-mathlib-cache: auto`, `use-github-cache: true`, `build-args: "UnsorryGoals"`), regenerates statement-binding modules, runs `lake build UnsorryLibrary --wfail`, and runs the cheap authoritative checks. This warms the GitHub/Lake cache before the heavy audit and replay jobs start.
- `gate_a_audit` and `gate_a_replay` each check out the tree, restore the warmed Lean cache, regenerate statement-binding modules, and run `lake build UnsorryLibrary --wfail` before their verifier. The duplicated build step is intentional: the generated binding files are not checked in, and each isolated runner must reconstruct the exact verification tree. With cache hits, this should be much cheaper than the verifier pass and lets audit and replay overlap wall time.
- The aggregate `gate-a` job depends on `detect`, `gate_a_prepare`, `gate_a_audit`, and `gate_a_replay`, and fails if any heavy job fails. Branch protection continues to require only the `gate-a` context.
- `lake build UnsorryLibrary --wfail` — verified: exits 1 on a sorried library module, fresh **and** replayed from Lake's warning cache; exits 0 clean.
- `python3 -m tools.gate_a.parallel_modules audit --jobs 1 [--base <sha>]` runs the authoritative `axiom_audit` and merges the per-chunk results into one valid JSON report. On PRs **and on push to `main`** (ADR-048 Phase 2), `--base` scopes the audit to changed library modules plus their reverse-import closure and changed goals; unchanged declarations were already audited on `main`. The base is `pull_request.base.sha` on a PR and `github.event.before` on a push. If the diff cannot be computed, the base is the zero/empty SHA (first push), or any gate/tooling/global-impact path changed (`forces_full_audit`), the tool falls back to a full audit; the scheduled `gate-a-full-replay` workflow runs the full audit backstop daily. Goals retain `--allow-sorry`. Execution is **serial**: each `axiom_audit` process holds a full mathlib image (~6–7 GB), so two concurrent ones peak ~13 GB and evict the olean page cache instead of going faster. Any chunk failure fails the step (SPEC-006-A). Raise to `--jobs 2`+ only on a runner with materially more RAM (e.g. a 32 GB profile).
- `python3 -m tools.gate_a.parallel_modules replay --jobs 1 [--base <sha>]` kernel-replays changed library modules plus their reverse-import closure on PRs **and on push to `main`** (ADR-033 + ADR-048 Phase 2; base = `github.event.before` on a push), and every library module when an olean-invalidating change (or the zero/empty base) invalidates the incremental assumption — and on the scheduled `gate-a-full-replay` backstop. Run **serially** (one `leanchecker` over the library at a time): leanchecker holds ~all of mathlib resident per process, so concurrency multiplies the image and OOMs a standard runner. `REPLAY_CHUNK_SIZE` is overridable via `UNSORRY_REPLAY_CHUNK` so a full replay fits a constrained runner with a small chunk. Re-parallelizing requires more RAM plus an implementation change to make effective replay jobs >1.
- **Forbidden elaboration options** (`python3 -m tools.gate_a.check_library_options library`) — **authoritative** for the autoImplicit vector, not a belt. The build, axiom audit and leanchecker all *pass* a vacuous theorem enabled by `set_option autoImplicit true` (it is sound, merely meaningless — verified in sandbox and by W3 red-team PR #64), so the scan is the only layer that catches it. It scans every `library/**/*.lean` whole-file with all whitespace collapsed, so splitting the option across lines cannot evade it (the exact #64 bypass). `autoImplicit`/`relaxedAutoImplicit` have no legitimate use in the verified library. Self-tested by `tools/gate_a/tests/`.
- Textual lint (belt only): fail if the PR diff under `library/` matches `\b(sorry|admit|sorryAx|native_decide|axiom|unsafe|implemented_by|extern)\b`. Findings duplicate the audit; the value is a faster, louder failure.
- Footprint publishing: upload the audit JSON as artifact `axiom-report` (durable evidence) and upsert a sticky PR comment (HTML marker `<!-- axiom-report -->`) with the declarations audited in that run. PR comments may be scoped; `main` runs retain the full footprint backstop.

## Required-check configuration

Branch protection on `main` requires contexts `gate-b` and `gate-a` exactly (job names are load-bearing; renaming a job without updating protection blocks all merges — ADR-005 trade-off).

## Acceptance criteria (PR-9)

1. A docs-only PR goes green in under a minute (detect short-circuit) with `gate-a` reported.
2. A PR adding a sorried theorem to `library/` fails `gate-a` (wfail layer) — exercised for real in the Stage-4 red-team (W3).
3. A clean library PR gets the axiom-report artifact and the sticky footprint comment.
4. Warm-cache wall time ≤ ~10 min.

Superseded runs for the same PR or `main` ref are cancelled so stale commits do
not occupy runners while a newer Gate A result is pending.
