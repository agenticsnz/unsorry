import Mathlib

/-- Goal `abstract-regular-polyhedron-realizable-iff`: for `p, q ≥ 3`, the
Schläfli pair `(p,q)` is one of the five Platonic pairs **iff** the combinatorial
Euler constraints `p·F = 2E`, `q·V = 2E`, `V+F = E+2` have a solution with
`V, F > 0`. Forward: exhibit the five solids. Backward: the constraints force
`pq < 2(p+q)`, so `p,q ≤ 5`, and the finite case split lands in the set. See
`library/index/`. -/
theorem abstract_regular_polyhedron_realizable_iff (p q : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q) :
    (p, q) ∈ ({(3, 3), (3, 4), (4, 3), (3, 5), (5, 3)} : Finset (ℕ × ℕ)) ↔
      ∃ V E F : ℕ, 0 < V ∧ 0 < F ∧ p * F = 2 * E ∧ q * V = 2 * E ∧ V + F = E + 2 := by
  constructor
  · intro hmem
    fin_cases hmem
    · exact ⟨4, 6, 4, by decide⟩
    · exact ⟨6, 12, 8, by decide⟩
    · exact ⟨8, 12, 6, by decide⟩
    · exact ⟨12, 30, 20, by decide⟩
    · exact ⟨20, 30, 12, by decide⟩
  · rintro ⟨V, E, F, hV, hF, h1, h2, h3⟩
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
    have hpqlt : p * q < 2 * (p + q) := by nlinarith [key, hE]
    have hp5 : p ≤ 5 := by nlinarith [hpqlt, hq]
    have hq5 : q ≤ 5 := by nlinarith [hpqlt, hp]
    interval_cases p <;> interval_cases q <;> first | decide | (exfalso; omega)
