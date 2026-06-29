import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_264_pow_23_sub_pow_thirteen (n : ℤ) : (264 : ℤ) ∣ n ^ 23 - n ^ 13 := by
  have h : ∀ m : ZMod 264, m ^ 23 - m ^ 13 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 13 : ℤ) : ZMod 264) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 13) 264).mp hz
  exact_mod_cast hdvd
