import Mathlib

/-- Goal `prod-range-one-sub-recip-succ-sq`: the telescoping product
`∏_{k=1}^{n} (1 - 1/(k+1)²) = (n+2)/(2(n+1))` over `ℚ` (for `n ≥ 1`). Induction
from the base `n = 1` via `Nat.le_induction`. See `library/index/`. -/
theorem prod_range_one_sub_recip_succ_sq (n : ℕ) (hn : 1 ≤ n) :
    ∏ k ∈ Finset.Icc 1 n, ((1 : ℚ) - 1 / (((k : ℚ) + 1) ^ 2))
      = ((n : ℚ) + 2) / (2 * ((n : ℚ) + 1)) := by
  induction n, hn using Nat.le_induction with
  | base => norm_num [Finset.Icc_self, Finset.prod_singleton]
  | succ m hm ih =>
    rw [Finset.prod_Icc_succ_top (by omega : 1 ≤ m + 1), ih]
    have h1 : (m : ℚ) + 1 ≠ 0 := by positivity
    have h2 : (m : ℚ) + 2 ≠ 0 := by positivity
    push_cast
    field_simp
    ring
