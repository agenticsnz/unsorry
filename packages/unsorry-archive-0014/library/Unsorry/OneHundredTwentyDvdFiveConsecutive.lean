import Mathlib

theorem one_hundred_twenty_dvd_five_consecutive (n : ℤ) :
    (120 : ℤ) ∣ n * (n + 1) * (n + 2) * (n + 3) * (n + 4) := by
  have h0 : (8 : ℤ) ∣ n * (n + 1) * (n + 2) * (n + 3) * (n + 4) := by
    suffices hh : ((n * (n + 1) * (n + 2) * (n + 3) * (n + 4) : ℤ) : ZMod 8) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n + 1) * (n + 2) * (n + 3) * (n + 4)) 8).mp hh
    push_cast
    generalize (n : ZMod 8) = x
    revert x
    decide
  have h1 : (3 : ℤ) ∣ n * (n + 1) * (n + 2) * (n + 3) * (n + 4) := by
    suffices hh : ((n * (n + 1) * (n + 2) * (n + 3) * (n + 4) : ℤ) : ZMod 3) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n + 1) * (n + 2) * (n + 3) * (n + 4)) 3).mp hh
    push_cast
    generalize (n : ZMod 3) = x
    revert x
    decide
  have h2 : (5 : ℤ) ∣ n * (n + 1) * (n + 2) * (n + 3) * (n + 4) := by
    suffices hh : ((n * (n + 1) * (n + 2) * (n + 3) * (n + 4) : ℤ) : ZMod 5) = 0 by
      exact_mod_cast (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n + 1) * (n + 2) * (n + 3) * (n + 4)) 5).mp hh
    push_cast
    generalize (n : ZMod 5) = x
    revert x
    decide
  have co1 : IsCoprime ((8) : ℤ) (3 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc1 : ((8) * 3 : ℤ) ∣ n * (n + 1) * (n + 2) * (n + 3) * (n + 4) := co1.mul_dvd h0 h1
  have co2 : IsCoprime (((8) * 3) : ℤ) (5 : ℤ) := by
    rw [Int.isCoprime_iff_gcd_eq_one]; decide
  have acc2 : (((8) * 3) * 5 : ℤ) ∣ n * (n + 1) * (n + 2) * (n + 3) * (n + 4) := co2.mul_dvd acc1 h2
  have keq : ((((8) * 3) * 5) : ℤ) = (120 : ℤ) := by norm_num
  rwa [keq] at acc2
