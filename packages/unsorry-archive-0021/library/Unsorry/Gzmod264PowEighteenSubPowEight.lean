import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_eighteen_sub_pow_eight (n : ℤ) : (264 : ℤ) ∣ n ^ 18 - n ^ 8 := by
  have h : ∀ m : ZMod 264, m ^ 18 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 18 - n ^ 8 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 18 - n ^ 8) 264).mp hz
  exact_mod_cast hdvd
