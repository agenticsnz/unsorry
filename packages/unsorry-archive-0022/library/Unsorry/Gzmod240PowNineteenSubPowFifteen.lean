import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_nineteen_sub_pow_fifteen (n : ℤ) : (240 : ℤ) ∣ n ^ 19 - n ^ 15 := by
  have h : ∀ m : ZMod 240, m ^ 19 - m ^ 15 = 0 := by decide
  have hz : ((n ^ 19 - n ^ 15 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 19 - n ^ 15) 240).mp hz
  exact_mod_cast hdvd
