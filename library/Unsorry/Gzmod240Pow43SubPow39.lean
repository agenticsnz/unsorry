import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_43_sub_pow_39 (n : ℤ) : (240 : ℤ) ∣ n ^ 43 - n ^ 39 := by
  have h : ∀ m : ZMod 240, m ^ 43 - m ^ 39 = 0 := by decide
  have hz : ((n ^ 43 - n ^ 39 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 43 - n ^ 39) 240).mp hz
  exact_mod_cast hdvd
