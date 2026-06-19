import Mathlib

/-- Goal `sum-icc-recip-four-consecutive-product-telescope`: the telescoping sum
`∑_{k=1}^{n} 1/(k(k+1)(k+2)(k+3)) = 1/18 - 1/(3(n+1)(n+2)(n+3))` over `ℚ` (n ≥ 1).
Induction from `n = 1` via `Nat.le_induction`. See `library/index/`. -/
theorem sum_icc_recip_four_consecutive_product_telescope (n : ℕ) (hn : 1 ≤ n) :
    ∑ k ∈ Finset.Icc 1 n, (1 : ℚ) / (k * (k + 1) * (k + 2) * (k + 3))
      = 1 / 18 - 1 / (3 * (n + 1) * (n + 2) * (n + 3)) := by
  induction n, hn using Nat.le_induction with
  | base => norm_num [Finset.Icc_self, Finset.sum_singleton]
  | succ m hm ih =>
    rw [Finset.sum_Icc_succ_top (by omega : 1 ≤ m + 1), ih]
    have h1 : (m : ℚ) + 1 ≠ 0 := by positivity
    have h2 : (m : ℚ) + 2 ≠ 0 := by positivity
    have h3 : (m : ℚ) + 3 ≠ 0 := by positivity
    have h4 : (m : ℚ) + 4 ≠ 0 := by positivity
    push_cast
    field_simp
    ring
