import Mathlib

set_option maxRecDepth 20000 in
theorem dvd_510_pow_thirtythree_sub_pow_seventeen (n : ℤ) : (510 : ℤ) ∣ n ^ 33 - n ^ 17 := by
  have h0 : (2 : ℤ) ∣ n ^ 33 - n ^ 17 := by
    suffices hh : ((n ^ 33 - n ^ 17 : ℤ) : ZMod 2) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 33 - n ^ 17) 2).mp hh
    push_cast
    generalize (n : ZMod 2) = x
    revert x
    decide
  have h1 : (3 : ℤ) ∣ n ^ 33 - n ^ 17 := by
    suffices hh : ((n ^ 33 - n ^ 17 : ℤ) : ZMod 3) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 33 - n ^ 17) 3).mp hh
    push_cast
    generalize (n : ZMod 3) = x
    revert x
    decide
  have h2 : (5 : ℤ) ∣ n ^ 33 - n ^ 17 := by
    suffices hh : ((n ^ 33 - n ^ 17 : ℤ) : ZMod 5) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 33 - n ^ 17) 5).mp hh
    push_cast
    generalize (n : ZMod 5) = x
    revert x
    decide
  have h3 : (17 : ℤ) ∣ n ^ 33 - n ^ 17 := by
    suffices hh : ((n ^ 33 - n ^ 17 : ℤ) : ZMod 17) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 33 - n ^ 17) 17).mp hh
    push_cast
    generalize (n : ZMod 17) = x
    revert x
    decide
  have co1 : IsCoprime ((2) : ℤ) (3 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((2) * 3 : ℤ) ∣ n ^ 33 - n ^ 17 := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((2) * 3) : ℤ) (5 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((2) * 3) * 5 : ℤ) ∣ n ^ 33 - n ^ 17 := co2.mul_dvd acc1 h2
  have co3 : IsCoprime ((((2) * 3) * 5) : ℤ) (17 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc3 : ((((2) * 3) * 5) * 17 : ℤ) ∣ n ^ 33 - n ^ 17 := co3.mul_dvd acc2 h3
  have keq : (((((2) * 3) * 5) * 17) : ℤ) = (510 : ℤ) := by norm_num
  rwa [keq] at acc3
