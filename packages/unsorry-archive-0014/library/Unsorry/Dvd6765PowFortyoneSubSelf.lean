import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_6765_pow_fortyone_sub_self (n : ℤ) : (6765 : ℤ) ∣ n ^ 41 - n := by
  have h0 : (3 : ℤ) ∣ n ^ 41 - n := by
    suffices hh : ((n ^ 41 - n : ℤ) : ZMod 3) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 41 - n) 3).mp hh
    push_cast
    generalize (n : ZMod 3) = x
    revert x
    decide
  have h1 : (5 : ℤ) ∣ n ^ 41 - n := by
    suffices hh : ((n ^ 41 - n : ℤ) : ZMod 5) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 41 - n) 5).mp hh
    push_cast
    generalize (n : ZMod 5) = x
    revert x
    decide
  have h2 : (11 : ℤ) ∣ n ^ 41 - n := by
    suffices hh : ((n ^ 41 - n : ℤ) : ZMod 11) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 41 - n) 11).mp hh
    push_cast
    generalize (n : ZMod 11) = x
    revert x
    decide
  have h3 : (41 : ℤ) ∣ n ^ 41 - n := by
    suffices hh : ((n ^ 41 - n : ℤ) : ZMod 41) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 41 - n) 41).mp hh
    push_cast
    generalize (n : ZMod 41) = x
    revert x
    decide
  have co1 : IsCoprime ((3) : ℤ) (5 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((3) * 5 : ℤ) ∣ n ^ 41 - n := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((3) * 5) : ℤ) (11 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((3) * 5) * 11 : ℤ) ∣ n ^ 41 - n := co2.mul_dvd acc1 h2
  have co3 : IsCoprime ((((3) * 5) * 11) : ℤ) (41 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc3 : ((((3) * 5) * 11) * 41 : ℤ) ∣ n ^ 41 - n := co3.mul_dvd acc2 h3
  have keq : (((((3) * 5) * 11) * 41) : ℤ) = (6765 : ℤ) := by norm_num
  rwa [keq] at acc3
