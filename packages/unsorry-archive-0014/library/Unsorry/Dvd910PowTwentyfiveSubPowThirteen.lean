import Mathlib

set_option maxRecDepth 100000 in
theorem dvd_910_pow_twentyfive_sub_pow_thirteen (n : ℤ) :
    (910 : ℤ) ∣ n^25 - n^13 := by
  have h0 : (2 : ℤ) ∣ n^25 - n^13 := by
    suffices hh : ((n^25 - n^13 : ℤ) : ZMod 2) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n^25 - n^13) 2).mp hh
    push_cast
    generalize (n : ZMod 2) = x
    revert x
    decide
  have h1 : (5 : ℤ) ∣ n^25 - n^13 := by
    suffices hh : ((n^25 - n^13 : ℤ) : ZMod 5) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n^25 - n^13) 5).mp hh
    push_cast
    generalize (n : ZMod 5) = x
    revert x
    decide
  have h2 : (7 : ℤ) ∣ n^25 - n^13 := by
    suffices hh : ((n^25 - n^13 : ℤ) : ZMod 7) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n^25 - n^13) 7).mp hh
    push_cast
    generalize (n : ZMod 7) = x
    revert x
    decide
  have h3 : (13 : ℤ) ∣ n^25 - n^13 := by
    suffices hh : ((n^25 - n^13 : ℤ) : ZMod 13) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n^25 - n^13) 13).mp hh
    push_cast
    generalize (n : ZMod 13) = x
    revert x
    decide
  have co1 : IsCoprime ((2) : ℤ) (5 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((2) * 5 : ℤ) ∣ n^25 - n^13 := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((2) * 5) : ℤ) (7 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((2) * 5) * 7 : ℤ) ∣ n^25 - n^13 := co2.mul_dvd acc1 h2
  have co3 : IsCoprime ((((2) * 5) * 7) : ℤ) (13 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc3 : ((((2) * 5) * 7) * 13 : ℤ) ∣ n^25 - n^13 := co3.mul_dvd acc2 h3
  have keq : (((((2) * 5) * 7) * 13) : ℤ) = (910 : ℤ) := by norm_num
  rwa [keq] at acc3
