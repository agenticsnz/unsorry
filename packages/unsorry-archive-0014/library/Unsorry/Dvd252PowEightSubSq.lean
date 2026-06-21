import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_252_pow_eight_sub_sq (n : ℤ) : (252 : ℤ) ∣ n ^ 8 - n ^ 2 := by
  have h0 : (4 : ℤ) ∣ n ^ 8 - n ^ 2 := by
    suffices hh : ((n ^ 8 - n ^ 2 : ℤ) : ZMod 4) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 8 - n ^ 2) 4).mp hh
    push_cast
    generalize (n : ZMod 4) = x
    revert x
    decide
  have h1 : (9 : ℤ) ∣ n ^ 8 - n ^ 2 := by
    suffices hh : ((n ^ 8 - n ^ 2 : ℤ) : ZMod 9) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 8 - n ^ 2) 9).mp hh
    push_cast
    generalize (n : ZMod 9) = x
    revert x
    decide
  have h2 : (7 : ℤ) ∣ n ^ 8 - n ^ 2 := by
    suffices hh : ((n ^ 8 - n ^ 2 : ℤ) : ZMod 7) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 8 - n ^ 2) 7).mp hh
    push_cast
    generalize (n : ZMod 7) = x
    revert x
    decide
  have co1 : IsCoprime ((4) : ℤ) (9 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((4) * 9 : ℤ) ∣ n ^ 8 - n ^ 2 := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((4) * 9) : ℤ) (7 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((4) * 9) * 7 : ℤ) ∣ n ^ 8 - n ^ 2 := co2.mul_dvd acc1 h2
  have keq : ((((4) * 9) * 7) : ℤ) = (252 : ℤ) := by norm_num
  rwa [keq] at acc2
