import Mathlib

theorem realization_edge_in_set (p q V E F : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q)
    (hV : 0 < V) (hF : 0 < F) (h1 : p * F = 2 * E) (h2 : q * V = 2 * E) (h3 : V + F = E + 2) :
    E = 6 ∨ E = 12 ∨ E = 30 := by
  sorry
