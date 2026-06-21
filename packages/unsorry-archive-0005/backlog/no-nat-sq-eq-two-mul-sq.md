# no-nat-sq-eq-two-mul-sq

There are no positive naturals a, b with a² = 2·b² — ¬∃ a b, 0 < b ∧ a² = 2b²: the irrationality of √2 in elementary infinite-descent form.

- **Source:** Freek 100 (#1, irrationality of √2), infinite-descent / parity form
- **Reference:** Classic infinite descent: a²=2b² ⟹ a even ⟹ b even ⟹ a strictly smaller solution. mathlib proves `irrational_sqrt_two` over ℝ via prime factorisation; this self-contained ℕ descent statement (no reals, no `sqrt`) is absent and is the elementary heart of Freek #1.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14) — the ℝ irrationality is a different, heavier statement; triviality-gate non-trivial (ADR-035)
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14)
- **Difficulty:** 4
- **Decomposition sketch:** L1 lemma n² even ↔ n even (parity case split mod 2). L2 take a minimal witness a (Nat.find / strong induction). L3 a²=2b² ⟹ a even, set a=2c ⟹ b²=2c². L4 b<a contradicts minimality, closing by descent. Genuine well-founded descent — not one-shot.
