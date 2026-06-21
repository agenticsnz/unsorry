import Mathlib

theorem sum_centered_triangular_closed_form (n : ℕ) : 2 * ∑ k ∈ Finset.range n, (3 * (k + 1) * k / 2 + 1) = n * (n ^ 2 + 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    have h2 : 2 ∣ 3 * (m + 1) * m := by
      rcases Nat.even_or_odd m with hm | hm
      · exact Dvd.dvd.mul_left hm.two_dvd _
      · have he : Even (m + 1) := by simpa [Nat.even_add_one] using hm
        have : (2 : ℕ) ∣ 3 * (m + 1) := Dvd.dvd.mul_left he.two_dvd 3
        exact Dvd.dvd.mul_right this m
    obtain ⟨c, hc⟩ := h2
    rw [hc]
    have hdiv : 2 * c / 2 = c := by omega
    rw [hdiv]
    nlinarith [hc]