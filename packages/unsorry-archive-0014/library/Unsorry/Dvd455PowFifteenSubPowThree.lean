import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_455_pow_fifteen_sub_pow_three (n : ℤ) : (455 : ℤ) ∣ n ^ 15 - n ^ 3 := by
  have h0 : (5 : ℤ) ∣ n ^ 15 - n ^ 3 := by
    suffices hh : ((n ^ 15 - n ^ 3 : ℤ) : ZMod 5) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 3) 5).mp hh
    push_cast
    generalize (n : ZMod 5) = x
    revert x
    decide
  have h1 : (7 : ℤ) ∣ n ^ 15 - n ^ 3 := by
    suffices hh : ((n ^ 15 - n ^ 3 : ℤ) : ZMod 7) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 3) 7).mp hh
    push_cast
    generalize (n : ZMod 7) = x
    revert x
    decide
  have h2 : (13 : ℤ) ∣ n ^ 15 - n ^ 3 := by
    suffices hh : ((n ^ 15 - n ^ 3 : ℤ) : ZMod 13) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 3) 13).mp hh
    push_cast
    generalize (n : ZMod 13) = x
    revert x
    decide
  have co1 : IsCoprime ((5) : ℤ) (7 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((5) * 7 : ℤ) ∣ n ^ 15 - n ^ 3 := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((5) * 7) : ℤ) (13 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((5) * 7) * 13 : ℤ) ∣ n ^ 15 - n ^ 3 := co2.mul_dvd acc1 h2
  have keq : ((((5) * 7) * 13) : ℤ) = (455 : ℤ) := by norm_num
  rwa [keq] at acc2
