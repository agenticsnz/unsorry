import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_133_pow_nineteen_sub_self (n : ℤ) : (133 : ℤ) ∣ n ^ 19 - n := by
  have h0 : (7 : ℤ) ∣ n ^ 19 - n := by
    suffices hh : ((n ^ 19 - n : ℤ) : ZMod 7) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 19 - n) 7).mp hh
    push_cast
    generalize (n : ZMod 7) = x
    revert x
    decide
  have h1 : (19 : ℤ) ∣ n ^ 19 - n := by
    suffices hh : ((n ^ 19 - n : ℤ) : ZMod 19) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 19 - n) 19).mp hh
    push_cast
    generalize (n : ZMod 19) = x
    revert x
    decide
  have co1 : IsCoprime ((7) : ℤ) (19 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((7) * 19 : ℤ) ∣ n ^ 19 - n := co1.mul_dvd h0 h1
  have keq : (((7) * 19) : ℤ) = (133 : ℤ) := by norm_num
  rwa [keq] at acc1
