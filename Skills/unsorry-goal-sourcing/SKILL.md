---
name: unsorry-goal-sourcing
description: "Workflow for SOURCING new open Unsorry goals — generating new Lean problems for the swarm to prove, not proving existing ones. Use this whenever you want to add new targets/theorems/problems to the queue: find mathlib-absent theorems, propose or create new goals, write goals/<slug>.{lean,aisp} + backlog/<slug>.md triples, stage candidates in backlog/candidates/, run the absence/triviality gates, or open a chore(sourcing): PR — even if the user just says 'generate harder problems', 'add more theorems', 'feed the swarm', or 'source new goals'. For PROVING an existing goal, use unsorry-proof-authoring instead."
---

# Unsorry Goal Sourcing

## Purpose

Source new **open** goals — problems the swarm (or a prover) will later close. A
sourced goal is a theorem that is **already proven somewhere** but **plausibly
absent from the pinned mathlib**, stated in Lean with `sorry`, screened by the
gates, and recorded as a three-file *triple*. You are filling the top of the
funnel, not the bottom: you never write the proof here (that is
`unsorry-proof-authoring`).

The mandate (ADR-060, from #400): **harder problems, and many more of them** —
without lowering the bar or colliding with other contributors. Difficulty is
self-tagged and **not gate-enforced**, so *you* are the difficulty bar.

## Scope boundary (read before sourcing anything)

- Source only theorems that are **already proven** (in a paper, in another
  system, by hand) and **plausibly absent** from the pinned mathlib. **Never open
  conjectures** — an unproven statement is not a goal, it is a research project.
- A goal that a single tactic closes, or that mathlib already has under another
  name, is **not** a goal. The gates below catch both; trust them.
- Goal statements are **create-only** (ADR-018). A wrong or changed statement gets
  a **new slug**, never an in-place edit.

## The four gates (in order; full detail in references/sourcing-pipeline.md)

Run these for every candidate before it becomes a triple. Each gate is a real
tool with a meaningful exit code — interpret it, do not paper over it.

1. **Absence** — `python3 -m tools.sourcing.check_absence --pattern '<regex>' [--loogle '<q>'] --json`.
   Exit `0` = `no-local-match` (admit; **record the printed `mathlib_rev`**). Exit
   `1` = a pattern matched — review the hits and drop or re-scope. This is a
   name-grep pre-filter, not proof of absence.
2. **Type-check** — write `goals/<slug>.lean` and `lake build UnsorryGoals`. If it
   does not elaborate, the statement is wrong; fix it before going on.
3. **Non-triviality** — `python3 -m tools.sourcing.check_triviality goals/<slug>.lean --json`.
   Exit `0` admits (`non-trivial` | `allowlisted` | `override`). Exit `1`
   (`trivial`) drops it — a battery tactic closed it (or mathlib has it under
   another name, since the whole library is in scope). Exit `2` (`probe-error`)
   means the statement failed to elaborate: that is a **tooling gap to fix, never
   evidence of non-triviality** — do not admit on a probe-error.
4. **Provable + skeptic** — confirm the *intended* proof compiles
   (`lake env lean` on a scratch file), then run the adversarial skeptic
   (agents/skeptic.md) to argue the statement is a disguised named mathlib lemma.
   A goal nobody can see how to prove is not ready to source.

## Difficulty bar (you enforce it — no gate does)

Aim high. "The most difficult problems are the best problems."

- Target **difficulty ≥ 3** and prefer goals carrying **≥ 1 decomposition edge**
  (a goal you can see how to split has depth). Tag `difficulty` honestly (0–5).
- Source the **hard families in parallel** (ADR-031/043): Freek-#50 **Phase-2
  Euler substrate** *and* **Phase-3 library growth**. The triviality battery
  deliberately omits `nlinarith/positivity/field_simp/gcongr`, so multivariate
  **SOS / field / `gcongr` inequalities** and olympiad/PutnamBench/miniF2F targets
  survive by design — they are your reliable hard supply.
- Do **not** source substrate-blocked geometric statements that cannot type-check
  at the pinned mathlib (gate 2 will fail them). See
  references/themes-and-difficulty.md.

## Assemble the triple

Two tiers. Stage cheaply, promote deliberately.

- **Stage** survivors of gates 1+3 as checklist lines in
  `backlog/candidates/<theme>.md` (no build; Gate B does not validate that dir).
  Keep the backlog ≥200 ahead so the swarm never starves.
- **Promote** a candidate to a full triple with the assembler — it writes all
  three files in the exact SPEC-003-A fresh-goal schema and Gate-B-validates them:

  ```bash
  python3 -m tools.sourcing.gen_triples --slug <kebab-id> \
      --lean-sig '<signature after the theorem name>' \
      --statement '<one-line English>' --difficulty <0-5> \
      --source '...' --reference '...' --absence '...' \
      --triviality '...' --decomposition '...' --validate
  ```

  A fresh goal is always `status≜open`, `sha≜∅`. Templates and the exact schema
  are in references/triple-format.md and assets/. The assembler refuses to clobber
  an existing goal (ADR-018) — pick a new slug instead.

## Don't collide (no pre-claim; dedup at mine-time and merge-time)

There is **no claim** for sourcing — the claims branch is prove-only and
fork-inaccessible, and the volunteer claim substrate (ADR-053/054) is not built
yet. Collision is avoided by discipline, and a raced duplicate costs only wasted
compute (never an unsound or duplicated *merged* goal — ADR-018 plus the gates
catch survivors). So:

- Take **one `backlog/candidates/<theme>.md` per session** — two people on the
  same theme file conflict in git.
- `git fetch origin` and **dedup your slugs and statements against the live
  `origin/main` `goals/`** immediately before each batch.
- When the swarm is churning the shared `.git`, write via the **GitHub git API**
  tree path, not local `git add` (see references/fork-contributor-path.md).
- **Never** push to the claims branch or run `agent.sh` claim/push/merge from a
  fork.

## Open the PR and announce

- One PR titled **`chore(sourcing): <description>`**, **≤ 50 goals** (a 100-goal
  batch overran the 45-min `gate-a-prepare`; no gate enforces the cap — you do).
- Do **not** regenerate `docs/targets.md` (ADR-036 — it refreshes post-merge).
- After merge: post a 📣 comment on issue **#81**, update the program-status
  comment on **#400**, and flip the `backlog/candidates` checkboxes `[ ]`→`[x]`.
  PR-body and announcement templates are in assets/.
- Sourcing earns leaderboard credit (`tools/leaderboard --sourcing`); make sure
  `gh auth status` is your account, or set `UNSORRY_SOLVER=<handle>`.

When a sourced goal is later picked up for proving, the handoff is to
[unsorry-proof-authoring](../unsorry-proof-authoring/SKILL.md).

## References

- references/sourcing-pipeline.md — the four gates in full, with every exit code.
- references/triple-format.md — the exact `.lean` / `.aisp` / backlog schema.
- references/themes-and-difficulty.md — hard families + the substrate ceiling.
- references/fork-contributor-path.md — fork PRs, Gate B on ubuntu-latest, credit.
