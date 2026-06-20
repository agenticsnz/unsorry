import Mathlib

theorem nicomachus_sum_cubes_eq_sum_id_sq (n : ℕ) : (∑ k ∈ Finset.range n, k^3) = (∑ k ∈ Finset.range n, k)^2 := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Finset.sum_range_succ, ih]
    have h2 : (∑ k ∈ Finset.range m, k) * 2 = m * (m - 1) := Finset.sum_range_id_mul_two m
    set S := ∑ k ∈ Finset.range m, k with hS
    -- Goal: S^2 + m^3 = (S + m)^2 = S^2 + 2*S*m + m^2
    have key : m^3 = 2 * S * m + m^2 := by
      rcases m with _ | p
      · simp
      · have : S * 2 = (p + 1) * p := by
          rw [h2]; simp
        nlinarith [this]
    nlinarith [key]