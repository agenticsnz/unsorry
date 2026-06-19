import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_273_pow_fourteen_sub_sq (n : ℤ) : (273 : ℤ) ∣ n ^ 14 - n ^ 2 := by
  have h0 : (3 : ℤ) ∣ n ^ 14 - n ^ 2 := by
    suffices hh : ((n ^ 14 - n ^ 2 : ℤ) : ZMod 3) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 2) 3).mp hh
    push_cast
    generalize (n : ZMod 3) = x
    revert x
    decide
  have h1 : (7 : ℤ) ∣ n ^ 14 - n ^ 2 := by
    suffices hh : ((n ^ 14 - n ^ 2 : ℤ) : ZMod 7) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 2) 7).mp hh
    push_cast
    generalize (n : ZMod 7) = x
    revert x
    decide
  have h2 : (13 : ℤ) ∣ n ^ 14 - n ^ 2 := by
    suffices hh : ((n ^ 14 - n ^ 2 : ℤ) : ZMod 13) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 2) 13).mp hh
    push_cast
    generalize (n : ZMod 13) = x
    revert x
    decide
  have co1 : IsCoprime ((3) : ℤ) (7 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((3) * 7 : ℤ) ∣ n ^ 14 - n ^ 2 := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((3) * 7) : ℤ) (13 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((3) * 7) * 13 : ℤ) ∣ n ^ 14 - n ^ 2 := co2.mul_dvd acc1 h2
  have keq : ((((3) * 7) * 13) : ℤ) = (273 : ℤ) := by norm_num
  rwa [keq] at acc2
