import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_38_sub_pow_34 (n : ℤ) : (240 : ℤ) ∣ n ^ 38 - n ^ 34 := by
  have h : ∀ m : ZMod 240, m ^ 38 - m ^ 34 = 0 := by decide
  have hz : ((n ^ 38 - n ^ 34 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 38 - n ^ 34) 240).mp hz
  exact_mod_cast hdvd
