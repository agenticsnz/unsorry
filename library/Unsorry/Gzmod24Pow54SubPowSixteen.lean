import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_54_sub_pow_sixteen (n : ℤ) : (24 : ℤ) ∣ n ^ 54 - n ^ 16 := by
  have h : ∀ m : ZMod 24, m ^ 54 - m ^ 16 = 0 := by decide
  have hz : ((n ^ 54 - n ^ 16 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 54 - n ^ 16) 24).mp hz
  exact_mod_cast hdvd
