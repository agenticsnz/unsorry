import Mathlib

set_option maxRecDepth 40000 in
theorem geud_42_pow_115_sub_self (n : ℤ) : (42 : ℤ) ∣ n ^ 115 - n := by
  have h : ∀ m : ZMod 42, m ^ 115 - m = 0 := by decide
  have hz : ((n ^ 115 - n : ℤ) : ZMod 42) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 115 - n) 42).mp hz
  exact_mod_cast hdvd
