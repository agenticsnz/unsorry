import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_170_pow_seventeen_sub_self (n : ℤ) : (170 : ℤ) ∣ n ^ 17 - n := by
  have h0 : (2 : ℤ) ∣ n ^ 17 - n := by
    suffices hh : ((n ^ 17 - n : ℤ) : ZMod 2) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 17 - n) 2).mp hh
    push_cast
    generalize (n : ZMod 2) = x
    revert x
    decide
  have h1 : (5 : ℤ) ∣ n ^ 17 - n := by
    suffices hh : ((n ^ 17 - n : ℤ) : ZMod 5) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 17 - n) 5).mp hh
    push_cast
    generalize (n : ZMod 5) = x
    revert x
    decide
  have h2 : (17 : ℤ) ∣ n ^ 17 - n := by
    suffices hh : ((n ^ 17 - n : ℤ) : ZMod 17) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 17 - n) 17).mp hh
    push_cast
    generalize (n : ZMod 17) = x
    revert x
    decide
  have co1 : IsCoprime ((2) : ℤ) (5 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((2) * 5 : ℤ) ∣ n ^ 17 - n := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((2) * 5) : ℤ) (17 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((2) * 5) * 17 : ℤ) ∣ n ^ 17 - n := co2.mul_dvd acc1 h2
  have keq : ((((2) * 5) * 17) : ℤ) = (170 : ℤ) := by norm_num
  rwa [keq] at acc2
