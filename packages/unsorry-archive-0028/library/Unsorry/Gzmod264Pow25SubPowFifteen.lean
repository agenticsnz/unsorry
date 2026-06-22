import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_25_sub_pow_fifteen (n : ℤ) : (264 : ℤ) ∣ n ^ 25 - n ^ 15 := by
  have h : ∀ m : ZMod 264, m ^ 25 - m ^ 15 = 0 := by decide
  have hz : ((n ^ 25 - n ^ 15 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 25 - n ^ 15) 264).mp hz
  exact_mod_cast hdvd
