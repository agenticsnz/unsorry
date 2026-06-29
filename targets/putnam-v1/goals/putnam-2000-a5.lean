import Mathlib

open Topology Filter

theorem putnam_2000_a5 (r : ℝ)
  (z : EuclideanSpace ℝ (Fin 2))
  (p : Fin 3 → (EuclideanSpace ℝ (Fin 2)))
  (rpos : r > 0)
  (pdiff : ∀ n m, (n ≠ m) → (p n ≠ p m))
  (pint : ∀ n i, p n i = round (p n i))
  (pcirc : ∀ n, p n ∈ Metric.sphere z r) :
  ∃ n m, (n ≠ m) ∧ (dist (p n) (p m) ≥ r ^ ((1 : ℝ) / 3)) := by
  sorry
