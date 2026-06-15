# sum-one-div-succ-mul-add-four-telescope

The sum over k<n of 3/((k+1)(k+4)) telescopes to 11/6 − 1/(n+1) − 1/(n+2) − 1/(n+3).

- **Source:** #400 Identity Engine (ADR-043) — telescoping family.
- **Reference:** The sum over k<n of 3/((k+1)(k+4)) telescopes to 11/6 − 1/(n+1) − 1/(n+2) − 1/(n+3). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 4
- **Decomposition sketch:** Induction; 3/((k+1)(k+4)) = 1/(k+1) − 1/(k+4), a gap-3 telescope leaving the head 1+1/2+1/3=11/6 minus the tail three terms; field_simp/ring.
