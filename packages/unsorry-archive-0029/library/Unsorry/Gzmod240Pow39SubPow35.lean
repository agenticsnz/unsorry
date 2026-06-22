import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_39_sub_pow_35 (n : ℤ) : (240 : ℤ) ∣ n ^ 39 - n ^ 35 := by
  have h : ∀ m : ZMod 240, m ^ 39 - m ^ 35 = 0 := by decide
  have hz : ((n ^ 39 - n ^ 35 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 39 - n ^ 35) 240).mp hz
  exact_mod_cast hdvd
