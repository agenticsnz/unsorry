import Mathlib

/-- Goal `sum-icc-two-div-k-mul-k-add-two-telescope`: the telescoping sum
`∑_{k=1}^{n} 2/(k(k+2)) = 3/2 - 1/(n+1) - 1/(n+2)` over `ℚ`. Induction on `n`.
See `library/index/`. -/
theorem sum_icc_two_div_k_mul_k_add_two_telescope (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n, (2 : ℚ) / ((k : ℚ) * ((k : ℚ) + 2))
      = 3 / 2 - 1 / ((n : ℚ) + 1) - 1 / ((n : ℚ) + 2) := by
  induction n with
  | zero => norm_num
  | succ m ih =>
    rw [Finset.sum_Icc_succ_top (by omega : 1 ≤ m + 1), ih]
    have h1 : (m : ℚ) + 1 ≠ 0 := by positivity
    have h2 : (m : ℚ) + 2 ≠ 0 := by positivity
    have h3 : (m : ℚ) + 3 ≠ 0 := by positivity
    push_cast
    field_simp
    ring
