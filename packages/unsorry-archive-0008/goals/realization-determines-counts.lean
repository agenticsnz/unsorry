import Mathlib

theorem realization_determines_counts (p q V E F V' E' F' : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q)
    (hV : 0 < V) (hF : 0 < F) (hV' : 0 < V') (hF' : 0 < F')
    (h1 : p * F = 2 * E) (h2 : q * V = 2 * E) (h3 : V + F = E + 2)
    (h1' : p * F' = 2 * E') (h2' : q * V' = 2 * E') (h3' : V' + F' = E' + 2) :
    V = V' ∧ E = E' ∧ F = F' := by
  sorry
