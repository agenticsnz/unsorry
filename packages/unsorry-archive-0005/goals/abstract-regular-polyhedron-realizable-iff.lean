import Mathlib

theorem abstract_regular_polyhedron_realizable_iff (p q : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q) :
    (p, q) ∈ ({(3, 3), (3, 4), (4, 3), (3, 5), (5, 3)} : Finset (ℕ × ℕ)) ↔
      ∃ V E F : ℕ, 0 < V ∧ 0 < F ∧ p * F = 2 * E ∧ q * V = 2 * E ∧ V + F = E + 2 := by
  sorry
