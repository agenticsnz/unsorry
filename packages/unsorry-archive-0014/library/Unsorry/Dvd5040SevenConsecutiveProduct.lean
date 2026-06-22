import Mathlib

set_option maxRecDepth 100000 in
theorem dvd_5040_seven_consecutive_product (n : ℤ) : (5040 : ℤ) ∣ n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9) := by
  have h0 : (16 : ℤ) ∣ n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9) := by
    suffices hh : ((n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9) : ℤ) : ZMod 16) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9)) 16).mp hh
    push_cast
    generalize (n : ZMod 16) = x
    revert x
    decide
  have h1 : (9 : ℤ) ∣ n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9) := by
    suffices hh : ((n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9) : ℤ) : ZMod 9) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9)) 9).mp hh
    push_cast
    generalize (n : ZMod 9) = x
    revert x
    decide
  have h2 : (5 : ℤ) ∣ n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9) := by
    suffices hh : ((n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9) : ℤ) : ZMod 5) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9)) 5).mp hh
    push_cast
    generalize (n : ZMod 5) = x
    revert x
    decide
  have h3 : (7 : ℤ) ∣ n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9) := by
    suffices hh : ((n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9) : ℤ) : ZMod 7) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9)) 7).mp hh
    push_cast
    generalize (n : ZMod 7) = x
    revert x
    decide
  have co1 : IsCoprime ((16) : ℤ) (9 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((16) * 9 : ℤ) ∣ n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9) := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((16) * 9) : ℤ) (5 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((16) * 9) * 5 : ℤ) ∣ n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9) := co2.mul_dvd acc1 h2
  have co3 : IsCoprime ((((16) * 9) * 5) : ℤ) (7 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc3 : ((((16) * 9) * 5) * 7 : ℤ) ∣ n * (n ^ 2 - 1) * (n ^ 2 - 4) * (n ^ 2 - 9) := co3.mul_dvd acc2 h3
  have keq : (((((16) * 9) * 5) * 7) : ℤ) = (5040 : ℤ) := by norm_num
  rwa [keq] at acc3
