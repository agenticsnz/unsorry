import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_47_sub_pow_43 (n : ℤ) : (240 : ℤ) ∣ n ^ 47 - n ^ 43 := by
  have h : ∀ m : ZMod 240, m ^ 47 - m ^ 43 = 0 := by decide
  have hz : ((n ^ 47 - n ^ 43 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 47 - n ^ 43) 240).mp hz
  exact_mod_cast hdvd
