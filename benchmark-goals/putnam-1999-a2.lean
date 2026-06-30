import Mathlib

theorem putnam_1999_a2 (p : Polynomial ℝ)
(hp : ∀ x, p.eval x ≥ 0)
: ∃ᵉ (k) (f : Fin k → Polynomial ℝ),
    k > 0 ∧
    ∀ x : ℝ, p.eval x = ∑ j : Fin k, ((f j).eval x) ^ 2 := by
  sorry
