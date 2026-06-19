import Mathlib

/-- Goal `realization-determines-counts`: two regular maps with the same Schläfli
pair `(p,q)` have the same `(V,E,F)`. The Euler constraints give
`(2(p+q) - pq)·E = 2pq` (and likewise for `E'`); the coefficient is positive, so
`E = E'`, and then `V = V'`, `F = F'` by cancelling `q`, `p`. See
`library/index/`. -/
theorem realization_determines_counts (p q V E F V' E' F' : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q)
    (_hV : 0 < V) (hF : 0 < F) (_hV' : 0 < V') (_hF' : 0 < F')
    (h1 : p * F = 2 * E) (h2 : q * V = 2 * E) (h3 : V + F = E + 2)
    (h1' : p * F' = 2 * E') (h2' : q * V' = 2 * E') (h3' : V' + F' = E' + 2) :
    V = V' ∧ E = E' ∧ F = F' := by
  have hE : 0 < E := by
    rcases Nat.eq_zero_or_pos E with h | h
    · rw [h, Nat.mul_zero] at h1
      rcases Nat.mul_eq_zero.mp h1 with h' | h' <;> omega
    · exact h
  have key : 2 * (p + q) * E = p * q * E + 2 * (p * q) := by
    have hV2 : p * q * V = 2 * p * E := by rw [mul_assoc, h2]; ring
    have hF2 : p * q * F = 2 * q * E := by rw [mul_comm p q, mul_assoc, h1]; ring
    have hexp : p * q * (V + F) = 2 * p * E + 2 * q * E := by rw [Nat.mul_add, hV2, hF2]
    rw [h3, Nat.mul_add] at hexp
    have hring : 2 * (p + q) * E = 2 * p * E + 2 * q * E := by ring
    rw [hring]; linarith [hexp]
  have key' : 2 * (p + q) * E' = p * q * E' + 2 * (p * q) := by
    have hV2 : p * q * V' = 2 * p * E' := by rw [mul_assoc, h2']; ring
    have hF2 : p * q * F' = 2 * q * E' := by rw [mul_comm p q, mul_assoc, h1']; ring
    have hexp : p * q * (V' + F') = 2 * p * E' + 2 * q * E' := by rw [Nat.mul_add, hV2, hF2]
    rw [h3', Nat.mul_add] at hexp
    have hring : 2 * (p + q) * E' = 2 * p * E' + 2 * q * E' := by ring
    rw [hring]; linarith [hexp]
  have hpqlt : p * q < 2 * (p + q) := by nlinarith [key, hE]
  have hcoef : 0 < 2 * (p + q) - p * q := by omega
  have hc : (2 * (p + q) - p * q) * E = 2 * (p * q) := by rw [Nat.sub_mul]; omega
  have hc' : (2 * (p + q) - p * q) * E' = 2 * (p * q) := by rw [Nat.sub_mul]; omega
  have hEE : E = E' := Nat.eq_of_mul_eq_mul_left hcoef (by rw [hc, hc'])
  refine ⟨?_, hEE, ?_⟩
  · exact Nat.eq_of_mul_eq_mul_left (show 0 < q by omega) (by rw [h2, h2', hEE])
  · exact Nat.eq_of_mul_eq_mul_left (show 0 < p by omega) (by rw [h1, h1', hEE])
