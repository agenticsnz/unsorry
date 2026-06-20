import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_276_pow_24_sub_pow_two (n : ℤ) : (276 : ℤ) ∣ n ^ 24 - n ^ 2 := by
  have h : ∀ m : ZMod 276, m ^ 24 - m ^ 2 = 0 := by decide
  have hz : ((n ^ 24 - n ^ 2 : ℤ) : ZMod 276) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 24 - n ^ 2) 276).mp hz
  exact_mod_cast hdvd
