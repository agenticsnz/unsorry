import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_23_sub_pow_nineteen (n : ℤ) : (240 : ℤ) ∣ n ^ 23 - n ^ 19 := by
  have h : ∀ m : ZMod 240, m ^ 23 - m ^ 19 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 19 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 19) 240).mp hz
  exact_mod_cast hdvd
