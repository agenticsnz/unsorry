import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_28_sub_pow_eighteen (n : ℤ) : (264 : ℤ) ∣ n ^ 28 - n ^ 18 := by
  have h : ∀ m : ZMod 264, m ^ 28 - m ^ 18 = 0 := by decide
  have hz : ((n ^ 28 - n ^ 18 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 28 - n ^ 18) 264).mp hz
  exact_mod_cast hdvd
