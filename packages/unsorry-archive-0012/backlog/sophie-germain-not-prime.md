# sophie-germain-not-prime

For a≥2, b≥1 the number a⁴+4b⁴ is composite (never prime) via the Sophie Germain factorisation.

- **Source:** #400 Identity Engine (ADR-043) — algebraic family.
- **Reference:** For a≥2, b≥1 the number a⁴+4b⁴ is composite (never prime) via the Sophie Germain factorisation. Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 4
- **Decomposition sketch:** Factor a⁴+4b⁴ into two factors each >1, then if prime divides the product it divides one factor, contradicting Int.le_of_dvd with the >1 bounds.
