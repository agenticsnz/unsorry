import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_360_pow_fifteen_sub_pow_three (n : ℤ) : (360 : ℤ) ∣ n ^ 15 - n ^ 3 := by
  have h0 : (8 : ℤ) ∣ n ^ 15 - n ^ 3 := by
    suffices hh : ((n ^ 15 - n ^ 3 : ℤ) : ZMod 8) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 3) 8).mp hh
    push_cast
    generalize (n : ZMod 8) = x
    revert x
    decide
  have h1 : (9 : ℤ) ∣ n ^ 15 - n ^ 3 := by
    suffices hh : ((n ^ 15 - n ^ 3 : ℤ) : ZMod 9) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 3) 9).mp hh
    push_cast
    generalize (n : ZMod 9) = x
    revert x
    decide
  have h2 : (5 : ℤ) ∣ n ^ 15 - n ^ 3 := by
    suffices hh : ((n ^ 15 - n ^ 3 : ℤ) : ZMod 5) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 3) 5).mp hh
    push_cast
    generalize (n : ZMod 5) = x
    revert x
    decide
  have co1 : IsCoprime ((8) : ℤ) (9 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((8) * 9 : ℤ) ∣ n ^ 15 - n ^ 3 := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((8) * 9) : ℤ) (5 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((8) * 9) * 5 : ℤ) ∣ n ^ 15 - n ^ 3 := co2.mul_dvd acc1 h2
  have keq : ((((8) * 9) * 5) : ℤ) = (360 : ℤ) := by norm_num
  rwa [keq] at acc2
