import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_282_pow_fortyseven_sub_self (n : ℤ) :
    (282 : ℤ) ∣ (n^47 - n) := by
  have h0 : (2 : ℤ) ∣ (n^47 - n) := by
    suffices hh : (((n^47 - n) : ℤ) : ZMod 2) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd ((n^47 - n)) 2).mp hh
    push_cast
    generalize (n : ZMod 2) = x
    revert x
    decide
  have h1 : (3 : ℤ) ∣ (n^47 - n) := by
    suffices hh : (((n^47 - n) : ℤ) : ZMod 3) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd ((n^47 - n)) 3).mp hh
    push_cast
    generalize (n : ZMod 3) = x
    revert x
    decide
  have h2 : (47 : ℤ) ∣ (n^47 - n) := by
    suffices hh : (((n^47 - n) : ℤ) : ZMod 47) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd ((n^47 - n)) 47).mp hh
    push_cast
    generalize (n : ZMod 47) = x
    revert x
    decide
  have co1 : IsCoprime ((2) : ℤ) (3 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((2) * 3 : ℤ) ∣ (n^47 - n) := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((2) * 3) : ℤ) (47 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((2) * 3) * 47 : ℤ) ∣ (n^47 - n) := co2.mul_dvd acc1 h2
  have keq : ((((2) * 3) * 47) : ℤ) = (282 : ℤ) := by norm_num
  rwa [keq] at acc2
