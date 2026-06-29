import Mathlib

open Set Function Metric
abbrev putnam_1998_b4_solution : Set (ℕ × ℕ) := {nm | let ⟨n,m⟩ := nm; multiplicity 2 n ≠ multiplicity 2 m}

theorem putnam_1998_b4 (quantity : ℕ → ℕ → ℤ)
  (hquantity : quantity = fun n m => ∑ i ∈ Finset.range (m * n), (-1)^(i/m + i/n))
  (n m : ℕ)
  (hnm : n > 0 ∧ m > 0) :
  quantity n m = 0 ↔ ⟨n, m⟩ ∈ putnam_1998_b4_solution := by
  sorry
