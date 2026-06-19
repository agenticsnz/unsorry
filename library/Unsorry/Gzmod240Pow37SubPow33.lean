import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_37_sub_pow_33 (n : ℤ) : (240 : ℤ) ∣ n ^ 37 - n ^ 33 := by
  have h : ∀ m : ZMod 240, m ^ 37 - m ^ 33 = 0 := by decide
  have hz : ((n ^ 37 - n ^ 33 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 37 - n ^ 33) 240).mp hz
  exact_mod_cast hdvd
