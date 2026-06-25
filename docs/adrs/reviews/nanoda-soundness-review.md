# Soundness review — `nanoda_lib` @ `f58f2f6` (0.4.10-beta)

ADR-096 / SPEC-096-A §4 acceptance **gate 2** (checker code/soundness review). Scope: is
nanoda trustworthy enough to run as a **co-gate** alongside the existing `leanchecker` `p=1`
gate (ADR-049)? It is **not** evaluated as a sole oracle. Pinned commit:
`f58f2f6d535e189a40fcb02ede8eb95f97a92d37` (the commit `tools/independent_check/setup.sh` and
the pilot workflow build).

## Verdict

**Qualified yes.** nanoda is a genuine, independent Lean type-checker (not parse-only): it
infers each definition/theorem's value-type and checks it def-eq against the declared type,
enforces the axiom whitelist, and independently reconstructs inductive recursors rather than
trusting the export's. It is sound enough to add as a **co-gate**. It is **not** yet audited to
the depth required to be the *sole* oracle (see Residual risk).

## Type-checking core (it really checks)

- Per-declaration entry `ExportFile::check_declar` (`src/tc.rs:83-106`): Definition/Theorem/
  Opaque infer the value's type and assert def-eq to the declared type —
  `let inferred_type = tc.infer(*val, Check); tc.assert_def_eq(inferred_type, d.info().ty)`
  (`src/tc.rs:92-93`). A proof term whose type ≠ the claimed statement fails at
  `assert_def_eq` → `assert!(self.def_eq(...))` (`src/tc.rs:925`).
- `infer` (`src/tc.rs:485-522`) is a full bidirectional inferer; `Check` mode does argument
  def-eq in application (`:540-551`) and binder-sort checks in lambda/pi/let (`:602-660`).
- `def_eq` (`src/tc.rs:927-974`): WHNF, lazy delta unfolding (`lazy_delta_step`, `:1243`),
  proof irrelevance, eta, eta-struct, quot/nat/string reduction. Universe equality uses the
  standard Lean `leq_core` IMax case-split (`src/level.rs:176-235`). Theorems must be `Prop`
  (`src/tc.rs:175-182`).
- Each declaration is checked against an environment cut off at **its own index**
  (`EnvLimit::ByName`, `src/util.rs:244`; `get_old_declar` enforces `idx < cutoff`,
  `src/env.rs:234-241`) — a declaration cannot use itself or later ones as its own proof.

## Axiom & positive-control enforcement (sound)

- Axioms admitted only if whitelisted (`axiom_permitted`, `src/parser.rs:445-448`); an
  unpermitted axiom either hard-errors (`src/parser.rs:752-753`) or is dropped from the
  environment (`:755`), in which case any declaration referencing it fails because
  `infer_const` panics on the missing const (`src/tc.rs:197`). **A sneaked `sorryAx` is
  rejected unless explicitly whitelisted.**
- Positive control: `pp_declars` names absent from the export hard-error before checking
  (`src/parser.rs:405-415`) — our "target theorem present" guard is real.
- Parser enforces continuous, acyclic back-references (`assert_ie`, `src/parser.rs:118-124`;
  index assert `:498`), so there is no forward-reference vector to exploit.

## Soundness smells / caveats (and how the unsorry config handles them)

- **No `unsafe`, `unimplemented!`, or `todo!`** anywhere. Only `unreachable!` is in
  non-checking arrow/lambda helpers (`src/expr.rs:484,494`).
- **Panics/`assert!` ARE the rejection mechanism** (~20 in `tc.rs`, ~21 in `inductive.rs`) —
  fail-closed. The parallel checker re-raises any thread panic via `join().expect()`
  (`src/tc.rs:140`), aborting the run rather than silently passing. → **Our wrapper treats any
  non-zero exit as non-ok** (`tools/pilot/export_checker_pilot.py::classify_checker`), so a
  panic = a rejected verdict. ✔
- **`nat_extension`/`string_extension`** (`try_reduce_nat`, `src/tc.rs:365`) are extra trusted
  compute, off by default in nanoda; **we enable both** (real exports carry Nat/String
  literals). Mitigation: the co-gate's companion oracle is `leanchecker` — the *actual Lean
  kernel* — which handles Nat/String natively, so we are not trusting a divergent literal
  semantics. ✔ (documented dependency, not a hole)
- **`unsafe_permit_all_axioms`** exists (`src/util.rs:915`) and would disable the whitelist;
  the config guards it against being combined with a whitelist (`:931-938`). → **We never set
  it** — we always pass an explicit `permitted_axioms`. ✔

## Residual risk (must be covered before nanoda could ever be the SOLE oracle)

1. **Inductive checker** (`src/inductive.rs`, 1677 lines) is where the subtlety lives — it
   reconstructs recursors/rec-rules and asserts the export's match
   (`assert_nonnested_recursors_def_eq`, `:47-72`) and runs strict positivity
   (`check_positivity1`, `:666-673`). A sole-oracle audit must cover nested/mutual inductives,
   the K-like rule (`to_ctor_when_k`, `src/tc.rs:985`), and specialization in depth.
2. **Export-format TCB:** nanoda trusts the *exporter* (Lean) to emit a well-formed `.export`.
   This is precisely why running it **alongside** leanchecker (a different implementation) is
   the right posture, not as a replacement that shares no TCB diversity.
3. **No fuzz/property corpus** of known-bad exports beyond unit tests (`src/tests/`).

**Conclusion for Phase 3b:** adopt nanoda as a **co-gate** (Step 2) on the pinned commit. The
binding gate (ADR-011) and `leanchecker` remain; none of the residual items block co-gate use,
and they define the audit backlog that gates any future "replace/sample" step.
