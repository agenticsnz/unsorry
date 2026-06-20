import Mathlib

theorem realization_edge_relation (p q V E F : ℕ) (h1 : p * F = 2 * E) (h2 : q * V = 2 * E) (h3 : V + F = E + 2) :
    2 * E * (p + q) = p * q * (E + 2) := by
  have hF : p * q * F = q * (2 * E) := by
    rw [← h1]; ring
  have hV : p * q * V = p * (2 * E) := by
    rw [show p * q * V = p * (q * V) by ring, h2]
  have key : p * q * (V + F) = 2 * E * (p + q) := by
    rw [Nat.mul_add, hF, hV]; ring
  rw [← h3]
  omega