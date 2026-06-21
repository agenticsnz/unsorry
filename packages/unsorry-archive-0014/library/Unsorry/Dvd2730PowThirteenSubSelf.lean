import Mathlib

theorem dvd_2730_pow_thirteen_sub_self (n : ℤ) : (2730 : ℤ) ∣ n ^ 13 - n := by
  have h0 : (2 : ℤ) ∣ n ^ 13 - n := by
    suffices hh : ((n ^ 13 - n : ℤ) : ZMod 2) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n) 2).mp hh
    push_cast
    generalize (n : ZMod 2) = x
    revert x
    decide
  have h1 : (3 : ℤ) ∣ n ^ 13 - n := by
    suffices hh : ((n ^ 13 - n : ℤ) : ZMod 3) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n) 3).mp hh
    push_cast
    generalize (n : ZMod 3) = x
    revert x
    decide
  have h2 : (5 : ℤ) ∣ n ^ 13 - n := by
    suffices hh : ((n ^ 13 - n : ℤ) : ZMod 5) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n) 5).mp hh
    push_cast
    generalize (n : ZMod 5) = x
    revert x
    decide
  have h3 : (7 : ℤ) ∣ n ^ 13 - n := by
    suffices hh : ((n ^ 13 - n : ℤ) : ZMod 7) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n) 7).mp hh
    push_cast
    generalize (n : ZMod 7) = x
    revert x
    decide
  have h4 : (13 : ℤ) ∣ n ^ 13 - n := by
    suffices hh : ((n ^ 13 - n : ℤ) : ZMod 13) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 13 - n) 13).mp hh
    push_cast
    generalize (n : ZMod 13) = x
    revert x
    decide
  have co1 : IsCoprime ((2) : ℤ) (3 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((2) * 3 : ℤ) ∣ n ^ 13 - n := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((2) * 3) : ℤ) (5 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((2) * 3) * 5 : ℤ) ∣ n ^ 13 - n := co2.mul_dvd acc1 h2
  have co3 : IsCoprime ((((2) * 3) * 5) : ℤ) (7 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc3 : ((((2) * 3) * 5) * 7 : ℤ) ∣ n ^ 13 - n := co3.mul_dvd acc2 h3
  have co4 : IsCoprime (((((2) * 3) * 5) * 7) : ℤ) (13 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc4 : (((((2) * 3) * 5) * 7) * 13 : ℤ) ∣ n ^ 13 - n := co4.mul_dvd acc3 h4
  have keq : ((((((2) * 3) * 5) * 7) * 13) : ℤ) = (2730 : ℤ) := by norm_num
  rwa [keq] at acc4
