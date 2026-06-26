import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic

theorem sum_icc_k_sub_one_div_factorial_eq_one_sub (n : ℕ) (hn : 1 ≤ n) :
    (∑ k ∈ Finset.Icc 1 n, ((k : ℚ) - 1) / Nat.factorial k) =
      1 - 1 / Nat.factorial n := by
  let f : ℕ → ℚ := fun k => 1 - 1 / (Nat.factorial (k - 1) : ℚ)
  calc
    (∑ k ∈ Finset.Icc 1 n, ((k : ℚ) - 1) / Nat.factorial k) =
        ∑ k ∈ Finset.Icc 1 n, (f (k + 1) - f k) := by
      refine Finset.sum_congr rfl ?_
      intro k hk
      have hk0 : k ≠ 0 := by
        exact Nat.ne_of_gt (lt_of_lt_of_le Nat.zero_lt_one (Finset.mem_Icc.mp hk).1)
      have hfac :
          (k : ℚ) * (Nat.factorial (k - 1) : ℚ) = (Nat.factorial k : ℚ) := by
        rw [← Nat.cast_mul, Nat.mul_factorial_pred hk0]
      have hfac_pred : (Nat.factorial (k - 1) : ℚ) ≠ 0 := by
        exact_mod_cast Nat.factorial_ne_zero (k - 1)
      have hfac_k : (Nat.factorial k : ℚ) ≠ 0 := by
        exact_mod_cast Nat.factorial_ne_zero k
      have hterm :
          ((k : ℚ) - 1) / (Nat.factorial k : ℚ) =
            (1 - 1 / (Nat.factorial k : ℚ)) -
              (1 - 1 / (Nat.factorial (k - 1) : ℚ)) := by
        field_simp [hfac_pred, hfac_k]
        rw [← hfac]
        ring
      simpa [f] using hterm
    _ = f (n + 1) - f 1 := by
      exact Finset.sum_Icc_sub hn f
    _ = 1 - 1 / Nat.factorial n := by
      simp [f]
