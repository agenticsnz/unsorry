import Mathlib

/-- The displacement-weighted sum of squared binomial coefficients over a full
row vanishes: `∑ k, (n - 2k) * C(n, k)^2 = 0`.

The proof uses the reflection `k ↦ n - k`. Since `C(n, n - k) = C(n, k)` and
`n - 2(n - k) = -(n - 2k)`, this reflection negates each summand, so the sum
equals its own negation and is therefore zero. -/
theorem sum_range_disp_mul_choose_sq_eq_zero (n : ℕ) :
    ∑ k ∈ Finset.range (n + 1), ((n : ℤ) - 2 * k) * (n.choose k : ℤ) ^ 2 = 0 := by
  set f : ℕ → ℤ := fun k => ((n : ℤ) - 2 * k) * (n.choose k : ℤ) ^ 2 with hf
  have hrefl : ∑ j ∈ Finset.range (n + 1), f (n + 1 - 1 - j)
      = ∑ j ∈ Finset.range (n + 1), f j := Finset.sum_range_reflect f (n + 1)
  have hterm : ∑ j ∈ Finset.range (n + 1), f (n + 1 - 1 - j)
      = ∑ j ∈ Finset.range (n + 1), -(f j) := by
    apply Finset.sum_congr rfl
    intro j hj
    rw [Finset.mem_range, Nat.lt_succ_iff] at hj
    simp only [hf]
    rw [Nat.add_sub_cancel, Nat.choose_symm hj]
    have hcast : ((n - j : ℕ) : ℤ) = (n : ℤ) - (j : ℤ) := by
      rw [Nat.cast_sub hj]
    rw [hcast]
    ring
  have heq : ∑ j ∈ Finset.range (n + 1), f j
      = ∑ j ∈ Finset.range (n + 1), -(f j) := by
    rw [← hrefl, hterm]
  have hcancel : ∑ j ∈ Finset.range (n + 1), -(f j)
      + ∑ j ∈ Finset.range (n + 1), f j = 0 := by
    rw [← Finset.sum_add_distrib]
    simp
  linarith
