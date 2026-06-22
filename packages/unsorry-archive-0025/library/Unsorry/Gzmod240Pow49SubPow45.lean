import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_49_sub_pow_45 (n : ℤ) : (240 : ℤ) ∣ n ^ 49 - n ^ 45 := by
  have h : ∀ m : ZMod 240, m ^ 49 - m ^ 45 = 0 := by decide
  have hz : ((n ^ 49 - n ^ 45 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 49 - n ^ 45) 240).mp hz
  exact_mod_cast hdvd
