import Mathlib

theorem sum_tetrahedral_eq_pentatope (n : ℕ) : 24 * ∑ k ∈ Finset.range (n + 1), k * (k + 1) * (k + 2) / 6 = n * (n + 1) * (n + 2) * (n + 3) := by
  have hdvd : ∀ m : ℕ, 6 ∣ m * (m + 1) * (m + 2) := by
    intro m
    induction m with
    | zero => decide
    | succ k ih =>
      have heq : (k + 1) * (k + 1 + 1) * (k + 1 + 2) = k * (k + 1) * (k + 2) + 3 * ((k + 1) * (k + 2)) := by ring
      rw [heq]
      refine Nat.dvd_add ih ?_
      have h2 : 2 ∣ (k + 1) * (k + 2) := Nat.two_dvd_mul_add_one (k + 1)
      obtain ⟨c, hc⟩ := h2
      exact ⟨c, by rw [hc]; ring⟩
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, Nat.mul_add, ih]
    obtain ⟨c, hc⟩ := hdvd (m + 1)
    rw [hc, Nat.mul_div_cancel_left c (by norm_num)]
    nlinarith [hc]