import Mathlib

/-- Goal `sum-icc-recip-km1-k-kp1-telescope`: the telescoping sum
`∑_{k=2}^{n} 1/((k-1)k(k+1)) = 1/4 - 1/(2n(n+1))` over `ℚ` (n ≥ 2). Induction from
`n = 2` via `Nat.le_induction`. See `library/index/`. -/
theorem sum_icc_recip_km1_k_kp1_telescope (n : ℕ) (hn : 2 ≤ n) :
    (∑ k ∈ Finset.Icc 2 n, (1 : ℚ) / (((k : ℚ) - 1) * k * (k + 1)))
      = 1 / 4 - 1 / (2 * (n : ℚ) * (n + 1)) := by
  induction n, hn using Nat.le_induction with
  | base => norm_num [Finset.Icc_self, Finset.sum_singleton]
  | succ m hm ih =>
    rw [Finset.sum_Icc_succ_top (by omega : 2 ≤ m + 1), ih]
    have hmq : (2 : ℚ) ≤ (m : ℚ) := by exact_mod_cast hm
    have h0 : (m : ℚ) ≠ 0 := by intro h; linarith
    have hsub : (m : ℚ) + 1 - 1 ≠ 0 := by intro h; linarith
    have h1 : (m : ℚ) + 1 ≠ 0 := by positivity
    have h2 : (m : ℚ) + 2 ≠ 0 := by positivity
    push_cast
    field_simp
    ring
