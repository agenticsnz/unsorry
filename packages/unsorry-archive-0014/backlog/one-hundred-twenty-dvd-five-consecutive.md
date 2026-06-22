# one-hundred-twenty-dvd-five-consecutive

120 = 5! divides the product of any five consecutive integers.

- **Source:** #400 Identity Engine (ADR-043) — divisibility family; extends twenty-four-dvd-four-consecutive.
- **Reference:** The product of k consecutive integers is divisible by k!; here k=5, k!=120. Extends the accepted twenty-four-dvd-four-consecutive (4!∣4-consecutive). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 3
- **Decomposition sketch:** set_option maxRecDepth 8000; ZMod 120 decide (∀ x : ZMod 120, x(x+1)(x+2)(x+3)(x+4)=0); push_cast; ZMod.intCast_zmod_eq_zero_iff_dvd. Verified to build (lake env lean).
