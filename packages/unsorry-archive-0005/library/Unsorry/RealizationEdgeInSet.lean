import Mathlib

/-- Goal `realization-edge-in-set`: the combinatorial Euler constraints of a
regular map (`p·F = 2E`, `q·V = 2E`, `V+F = E+2`, `p,q ≥ 3`, `V,F > 0`) force
`E ∈ {6, 12, 30}`. Combining the hypotheses gives `2E(p+q) = pqE + 2pq`, which
forces `pq < 2(p+q)`, hence `p,q ≤ 5`; the finite case split finishes. See
`library/index/`. -/
theorem realization_edge_in_set (p q V E F : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q)
    (_hV : 0 < V) (hF : 0 < F) (h1 : p * F = 2 * E) (h2 : q * V = 2 * E) (h3 : V + F = E + 2) :
    E = 6 ∨ E = 12 ∨ E = 30 := by
  have hE : 0 < E := by
    rcases Nat.eq_zero_or_pos E with h | h
    · rw [h, Nat.mul_zero] at h1
      rcases Nat.mul_eq_zero.mp h1 with h' | h' <;> omega
    · exact h
  -- Euler relation, derived without division.
  have key : 2 * p * E + 2 * q * E = p * q * E + 2 * (p * q) := by
    have hV2 : p * q * V = 2 * p * E := by rw [mul_assoc, h2]; ring
    have hF2 : p * q * F = 2 * q * E := by rw [mul_comm p q, mul_assoc, h1]; ring
    have hexp : p * q * (V + F) = 2 * p * E + 2 * q * E := by rw [Nat.mul_add, hV2, hF2]
    rw [h3, Nat.mul_add] at hexp
    linarith [hexp]
  -- pq < 2(p+q), hence p, q ≤ 5.
  have hpq : p * q < 2 * (p + q) := by nlinarith [key, hE]
  have hp5 : p ≤ 5 := by nlinarith [hpq, hq]
  have hq5 : q ≤ 5 := by nlinarith [hpq, hp]
  interval_cases p <;> interval_cases q <;> omega
