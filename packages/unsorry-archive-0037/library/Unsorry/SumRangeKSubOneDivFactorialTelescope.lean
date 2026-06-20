import Mathlib

theorem sum_range_k_sub_one_div_factorial_telescope (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n, ((k : ℝ) - 1) / k.factorial = 1 - 1 / n.factorial := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_Icc_succ_top (by omega), ih]
    rw [Nat.factorial_succ]
    have hm : (m.factorial : ℝ) ≠ 0 := by
      exact_mod_cast Nat.factorial_ne_zero m
    push_cast
    field_simp
    ring