import Mathlib

theorem abstract_regular_polyhedron_classification
    (p q V E F : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q) (hV : 0 < V) (hF : 0 < F)
    (hpF : p * F = 2 * E) (hqV : q * V = 2 * E) (hEuler : V + F = E + 2) :
    (p, q) ∈ ({(3, 3), (3, 4), (4, 3), (3, 5), (5, 3)} : Finset (ℕ × ℕ)) := by
  sorry
