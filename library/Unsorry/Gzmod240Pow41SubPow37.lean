import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_41_sub_pow_37 (n : ℤ) : (240 : ℤ) ∣ n ^ 41 - n ^ 37 := by
  have h : ∀ m : ZMod 240, m ^ 41 - m ^ 37 = 0 := by decide
  have hz : ((n ^ 41 - n ^ 37 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 41 - n ^ 37) 240).mp hz
  exact_mod_cast hdvd
