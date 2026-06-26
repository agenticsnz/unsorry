import Mathlib

theorem hackmath_3 (sol : Finset ℕ)
    (h_sol : ∀ s, s ∈ sol ↔ 1000 ≤ s ∧ s ≤ 9999 ∧ (Nat.digits 10 s).toFinset = {3, 5, 8, 9}) :
    sol.card = ((24) : ℕ ) := by
  sorry
