import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_42_sub_pow_38 (n : ℤ) : (240 : ℤ) ∣ n ^ 42 - n ^ 38 := by
  have h : ∀ m : ZMod 240, m ^ 42 - m ^ 38 = 0 := by decide
  have hz : ((n ^ 42 - n ^ 38 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 42 - n ^ 38) 240).mp hz
  exact_mod_cast hdvd
