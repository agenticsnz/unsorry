import Mathlib

/-- Goal `sum-icc-three-div-three-k-sub-one-three-k-add-two-telescope`: the
telescoping sum `∑_{k=1}^{n} 3/((3k-1)(3k+2)) = 1/2 - 1/(3n+2)` over `ℚ`.
Induction on `n`. See `library/index/`. -/
theorem sum_icc_three_div_three_k_sub_one_three_k_add_two_telescope (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n, (3 : ℚ) / ((3 * (k : ℚ) - 1) * (3 * (k : ℚ) + 2))
      = 1 / 2 - 1 / (3 * (n : ℚ) + 2) := by
  induction n with
  | zero => norm_num
  | succ m ih =>
    rw [Finset.sum_Icc_succ_top (by omega : 1 ≤ m + 1), ih]
    have hm : (0 : ℚ) ≤ (m : ℚ) := Nat.cast_nonneg m
    have h0 : 3 * (m : ℚ) + 2 ≠ 0 := by positivity
    have h1 : 3 * ((m : ℚ) + 1) - 1 ≠ 0 := by intro h; nlinarith
    have h2 : 3 * ((m : ℚ) + 1) + 2 ≠ 0 := by positivity
    push_cast
    field_simp
    ring
