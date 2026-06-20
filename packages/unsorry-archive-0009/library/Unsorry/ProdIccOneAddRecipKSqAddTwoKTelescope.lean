import Mathlib

/-- Goal `prod-icc-one-add-recip-k-sq-add-two-k-telescope`: the telescoping
product `∏_{k=1}^{n} (1 + 1/(k²+2k)) = 2(n+1)/(n+2)` over `ℚ` (n ≥ 1). Induction
from `n = 1` via `Nat.le_induction`. See `library/index/`. -/
theorem prod_icc_one_add_recip_k_sq_add_two_k_telescope (n : ℕ) (hn : 1 ≤ n) :
    (∏ k ∈ Finset.Icc 1 n, (1 + 1 / ((k : ℚ) ^ 2 + 2 * k))) = 2 * ((n : ℚ) + 1) / (n + 2) := by
  induction n, hn using Nat.le_induction with
  | base => norm_num [Finset.Icc_self, Finset.prod_singleton]
  | succ m hm ih =>
    rw [Finset.prod_Icc_succ_top (by omega : 1 ≤ m + 1), ih]
    have h2 : (m : ℚ) + 2 ≠ 0 := by positivity
    have h3 : (m : ℚ) + 3 ≠ 0 := by positivity
    have hd : ((m : ℚ) + 1) ^ 2 + 2 * ((m : ℚ) + 1) ≠ 0 := by positivity
    push_cast
    field_simp
    ring
