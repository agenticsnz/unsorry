import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_44_sub_pow_40 (n : ℤ) : (240 : ℤ) ∣ n ^ 44 - n ^ 40 := by
  have h : ∀ m : ZMod 240, m ^ 44 - m ^ 40 = 0 := by decide
  have hz : ((n ^ 44 - n ^ 40 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 44 - n ^ 40) 240).mp hz
  exact_mod_cast hdvd
