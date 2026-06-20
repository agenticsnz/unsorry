import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_630_pow_fourteen_sub_sq (n : ℤ) : (630 : ℤ) ∣ n ^ 14 - n ^ 2 := by
  have h0 : (2 : ℤ) ∣ n ^ 14 - n ^ 2 := by
    suffices hh : ((n ^ 14 - n ^ 2 : ℤ) : ZMod 2) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 2) 2).mp hh
    push_cast
    generalize (n : ZMod 2) = x
    revert x
    decide
  have h1 : (9 : ℤ) ∣ n ^ 14 - n ^ 2 := by
    suffices hh : ((n ^ 14 - n ^ 2 : ℤ) : ZMod 9) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 2) 9).mp hh
    push_cast
    generalize (n : ZMod 9) = x
    revert x
    decide
  have h2 : (5 : ℤ) ∣ n ^ 14 - n ^ 2 := by
    suffices hh : ((n ^ 14 - n ^ 2 : ℤ) : ZMod 5) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 2) 5).mp hh
    push_cast
    generalize (n : ZMod 5) = x
    revert x
    decide
  have h3 : (7 : ℤ) ∣ n ^ 14 - n ^ 2 := by
    suffices hh : ((n ^ 14 - n ^ 2 : ℤ) : ZMod 7) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 2) 7).mp hh
    push_cast
    generalize (n : ZMod 7) = x
    revert x
    decide
  have co1 : IsCoprime ((2) : ℤ) (9 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((2) * 9 : ℤ) ∣ n ^ 14 - n ^ 2 := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((2) * 9) : ℤ) (5 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((2) * 9) * 5 : ℤ) ∣ n ^ 14 - n ^ 2 := co2.mul_dvd acc1 h2
  have co3 : IsCoprime ((((2) * 9) * 5) : ℤ) (7 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc3 : ((((2) * 9) * 5) * 7 : ℤ) ∣ n ^ 14 - n ^ 2 := co3.mul_dvd acc2 h3
  have keq : (((((2) * 9) * 5) * 7) : ℤ) = (630 : ℤ) := by norm_num
  rwa [keq] at acc3
