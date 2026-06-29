import Mathlib

open Filter Topology Metric

theorem putnam_1999_b6 (S : Finset ℤ)
  (hSgt : ∀ s, s ∈ S → s > 1)
  (hSgcd : ∀ n, ∃ s ∈ S, Int.gcd s n = 1 ∨ Int.gcd s n = s) :
  ∃ᵉ (s ∈ S) (t ∈ S), Prime (Int.gcd s t) := by
  sorry
