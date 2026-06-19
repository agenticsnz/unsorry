import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_sixteen_sub_pow_fourteen (n : ℤ) : (24 : ℤ) ∣ n ^ 16 - n ^ 14 := by
  have h : ∀ m : ZMod 24, m ^ 16 - m ^ 14 = 0 := by decide
  have hz : ((n ^ 16 - n ^ 14 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 16 - n ^ 14) 24).mp hz
  exact_mod_cast hdvd
