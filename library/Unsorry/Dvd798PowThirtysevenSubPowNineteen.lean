import Mathlib

set_option maxRecDepth 100000 in
theorem dvd_798_pow_thirtyseven_sub_pow_nineteen (n : ℤ) :
    (798 : ℤ) ∣ n^37 - n^19 := by
  have h0 : (2 : ℤ) ∣ n^37 - n^19 := by
    suffices hh : ((n^37 - n^19 : ℤ) : ZMod 2) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n^37 - n^19) 2).mp hh
    push_cast
    generalize (n : ZMod 2) = x
    revert x
    decide
  have h1 : (3 : ℤ) ∣ n^37 - n^19 := by
    suffices hh : ((n^37 - n^19 : ℤ) : ZMod 3) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n^37 - n^19) 3).mp hh
    push_cast
    generalize (n : ZMod 3) = x
    revert x
    decide
  have h2 : (7 : ℤ) ∣ n^37 - n^19 := by
    suffices hh : ((n^37 - n^19 : ℤ) : ZMod 7) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n^37 - n^19) 7).mp hh
    push_cast
    generalize (n : ZMod 7) = x
    revert x
    decide
  have h3 : (19 : ℤ) ∣ n^37 - n^19 := by
    suffices hh : ((n^37 - n^19 : ℤ) : ZMod 19) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n^37 - n^19) 19).mp hh
    push_cast
    generalize (n : ZMod 19) = x
    revert x
    decide
  have co1 : IsCoprime ((2) : ℤ) (3 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((2) * 3 : ℤ) ∣ n^37 - n^19 := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((2) * 3) : ℤ) (7 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((2) * 3) * 7 : ℤ) ∣ n^37 - n^19 := co2.mul_dvd acc1 h2
  have co3 : IsCoprime ((((2) * 3) * 7) : ℤ) (19 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc3 : ((((2) * 3) * 7) * 19 : ℤ) ∣ n^37 - n^19 := co3.mul_dvd acc2 h3
  have keq : (((((2) * 3) * 7) * 19) : ℤ) = (798 : ℤ) := by norm_num
  rwa [keq] at acc3
