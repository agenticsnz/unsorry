import Mathlib

set_option maxRecDepth 40000 in
theorem geud_6_pow_thirtynine_sub_self (n : ℤ) : (6 : ℤ) ∣ n ^ 39 - n := by
  have h : ∀ m : ZMod 6, m ^ 39 - m = 0 := by decide
  have hz : ((n ^ 39 - n : ℤ) : ZMod 6) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 39 - n) 6).mp hz
  exact_mod_cast hdvd
