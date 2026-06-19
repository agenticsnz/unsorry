import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_1806_pow_fortythree_sub_self (n : ℤ) : (1806 : ℤ) ∣ n ^ 43 - n := by
  have h0 : (2 : ℤ) ∣ n ^ 43 - n := by
    suffices hh : ((n ^ 43 - n : ℤ) : ZMod 2) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 43 - n) 2).mp hh
    push_cast
    generalize (n : ZMod 2) = x
    revert x
    decide
  have h1 : (3 : ℤ) ∣ n ^ 43 - n := by
    suffices hh : ((n ^ 43 - n : ℤ) : ZMod 3) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 43 - n) 3).mp hh
    push_cast
    generalize (n : ZMod 3) = x
    revert x
    decide
  have h2 : (7 : ℤ) ∣ n ^ 43 - n := by
    suffices hh : ((n ^ 43 - n : ℤ) : ZMod 7) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 43 - n) 7).mp hh
    push_cast
    generalize (n : ZMod 7) = x
    revert x
    decide
  have h3 : (43 : ℤ) ∣ n ^ 43 - n := by
    suffices hh : ((n ^ 43 - n : ℤ) : ZMod 43) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 43 - n) 43).mp hh
    push_cast
    generalize (n : ZMod 43) = x
    revert x
    decide
  have co1 : IsCoprime ((2) : ℤ) (3 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((2) * 3 : ℤ) ∣ n ^ 43 - n := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((2) * 3) : ℤ) (7 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((2) * 3) * 7 : ℤ) ∣ n ^ 43 - n := co2.mul_dvd acc1 h2
  have co3 : IsCoprime ((((2) * 3) * 7) : ℤ) (43 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc3 : ((((2) * 3) * 7) * 43 : ℤ) ∣ n ^ 43 - n := co3.mul_dvd acc2 h3
  have keq : (((((2) * 3) * 7) * 43) : ℤ) = (1806 : ℤ) := by norm_num
  rwa [keq] at acc3
