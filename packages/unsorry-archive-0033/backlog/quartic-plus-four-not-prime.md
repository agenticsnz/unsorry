# quartic-plus-four-not-prime

For n≥2 the number n⁴+4 is composite (special Sophie Germain case b=1).

- **Source:** #400 Identity Engine (ADR-043) — algebraic family.
- **Reference:** For n≥2 the number n⁴+4 is composite (special Sophie Germain case b=1). Not a named mathlib lemma in this form.
- **Absence:** no-local-match (grep of pinned mathlib rev c5ea00351c, 2026-06-14); triviality-gate non-trivial (ADR-035).
- **Triviality:** machine-checked non-trivial (battery v1, rev c5ea00351c, 2026-06-14).
- **Difficulty:** 4
- **Decomposition sketch:** Factor n⁴+4=(n²−2n+2)(n²+2n+2), both factors >1 for n≥2; a prime dividing the product would divide a factor, contradicting Int.le_of_dvd.
