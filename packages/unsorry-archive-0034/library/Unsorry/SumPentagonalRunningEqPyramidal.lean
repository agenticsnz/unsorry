import Mathlib

theorem sum_pentagonal_running_eq_pyramidal (n : ℕ) : 2 * ∑ k ∈ Finset.range (n + 1), k * (3 * k - 1) / 2 = n ^ 2 * (n + 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    -- need: m^2*(m+1) + 2 * ((m+1)*(3*(m+1)-1)/2) = (m+1)^2*(m+2)
    have h : (m + 1) * (3 * (m + 1) - 1) / 2 * 2 = (m + 1) * (3 * (m + 1) - 1) := by
      apply Nat.div_mul_cancel
      rcases Nat.even_or_odd (m + 1) with he | ho
      · exact Dvd.dvd.mul_right he.two_dvd _
      · have : Even (3 * (m + 1) - 1) := by
          rcases ho with ⟨t, ht⟩
          refine ⟨3 * t + 1, ?_⟩
          omega
        exact Dvd.dvd.mul_left this.two_dvd _
    have h2 : 2 * ((m + 1) * (3 * (m + 1) - 1) / 2) = (m + 1) * (3 * (m + 1) - 1) := by
      rw [Nat.mul_comm]; exact h
    rw [h2]
    have : 3 * (m + 1) - 1 = 3 * m + 2 := by omega
    rw [this]
    ring