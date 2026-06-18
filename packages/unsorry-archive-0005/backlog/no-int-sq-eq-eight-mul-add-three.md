# no-int-sq-eq-eight-mul-add-three

No integer square has the form 8n+3 (squares are 0,1,4 mod 8).

- **Source:** Classic elementary number theory (library-growth batch, #400 plan Phase 3).
- **Reference:** No integer square has the form 8n+3 (squares are 0,1,4 mod 8). mathlib has `ZMod.pow_card` (Fermat) but not these specific named divisibility lemmas.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035) — stated over **all of ℤ**, so `decide` cannot enumerate and `omega` cannot see the nonlinear/modular structure.
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** ZMod 8: decide ∀ x, x²≠3; from m²=8n+3 derive (m:ZMod8)²=3, contradiction. Verified to build (lake env lean).
