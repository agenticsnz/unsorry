import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_45_sub_pow_41 (n : ℤ) : (240 : ℤ) ∣ n ^ 45 - n ^ 41 := by
  have h : ∀ m : ZMod 240, m ^ 45 - m ^ 41 = 0 := by decide
  have hz : ((n ^ 45 - n ^ 41 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 45 - n ^ 41) 240).mp hz
  exact_mod_cast hdvd
