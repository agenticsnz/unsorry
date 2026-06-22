import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_41_sub_pow_31 (n : ℤ) : (264 : ℤ) ∣ n ^ 41 - n ^ 31 := by
  have h : ∀ m : ZMod 264, m ^ 41 - m ^ 31 = 0 := by decide
  have hz : ((n ^ 41 - n ^ 31 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 41 - n ^ 31) 264).mp hz
  exact_mod_cast hdvd
