import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_138_pow_twentythree_sub_self (n : ℤ) : (138 : ℤ) ∣ n ^ 23 - n := by
  have h0 : (2 : ℤ) ∣ n ^ 23 - n := by
    suffices hh : ((n ^ 23 - n : ℤ) : ZMod 2) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n) 2).mp hh
    push_cast
    generalize (n : ZMod 2) = x
    revert x
    decide
  have h1 : (3 : ℤ) ∣ n ^ 23 - n := by
    suffices hh : ((n ^ 23 - n : ℤ) : ZMod 3) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n) 3).mp hh
    push_cast
    generalize (n : ZMod 3) = x
    revert x
    decide
  have h2 : (23 : ℤ) ∣ n ^ 23 - n := by
    suffices hh : ((n ^ 23 - n : ℤ) : ZMod 23) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n) 23).mp hh
    push_cast
    generalize (n : ZMod 23) = x
    revert x
    decide
  have co1 : IsCoprime ((2) : ℤ) (3 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((2) * 3 : ℤ) ∣ n ^ 23 - n := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((2) * 3) : ℤ) (23 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((2) * 3) * 23 : ℤ) ∣ n ^ 23 - n := co2.mul_dvd acc1 h2
  have keq : ((((2) * 3) * 23) : ℤ) = (138 : ℤ) := by norm_num
  rwa [keq] at acc2
