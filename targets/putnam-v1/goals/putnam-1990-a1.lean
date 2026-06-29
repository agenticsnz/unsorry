import Mathlib

open Filter Topology Nat
abbrev putnam_1990_a1_solution : (ℕ → ℤ) × (ℕ → ℤ) := (fun n : ℕ => (n)!, fun n : ℕ => 2 ^ n)

theorem putnam_1990_a1 (T : ℕ → ℤ)
    (hT012 : T 0 = 2 ∧ T 1 = 3 ∧ T 2 = 6)
    (hTn : ∀ n, T (n + 3) = (n + 7) * T (n + 2) - 4 * (n + 3) * T (n + 1) + (4 * n + 4) * T n) :
    T = putnam_1990_a1_solution.1 + putnam_1990_a1_solution.2 := by
  sorry
