import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_240_pow_nine_sub_pow_five (n : ℤ) : (240 : ℤ) ∣ n ^ 9 - n ^ 5 := by
  have h0 : (16 : ℤ) ∣ n ^ 9 - n ^ 5 := by
    suffices hh : ((n ^ 9 - n ^ 5 : ℤ) : ZMod 16) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 9 - n ^ 5) 16).mp hh
    push_cast
    generalize (n : ZMod 16) = x
    revert x
    decide
  have h1 : (3 : ℤ) ∣ n ^ 9 - n ^ 5 := by
    suffices hh : ((n ^ 9 - n ^ 5 : ℤ) : ZMod 3) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 9 - n ^ 5) 3).mp hh
    push_cast
    generalize (n : ZMod 3) = x
    revert x
    decide
  have h2 : (5 : ℤ) ∣ n ^ 9 - n ^ 5 := by
    suffices hh : ((n ^ 9 - n ^ 5 : ℤ) : ZMod 5) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 9 - n ^ 5) 5).mp hh
    push_cast
    generalize (n : ZMod 5) = x
    revert x
    decide
  have co1 : IsCoprime ((16) : ℤ) (3 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((16) * 3 : ℤ) ∣ n ^ 9 - n ^ 5 := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((16) * 3) : ℤ) (5 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((16) * 3) * 5 : ℤ) ∣ n ^ 9 - n ^ 5 := co2.mul_dvd acc1 h2
  have keq : ((((16) * 3) * 5) : ℤ) = (240 : ℤ) := by norm_num
  rwa [keq] at acc2
