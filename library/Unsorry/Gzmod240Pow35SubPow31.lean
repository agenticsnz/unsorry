import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_35_sub_pow_31 (n : ℤ) : (240 : ℤ) ∣ n ^ 35 - n ^ 31 := by
  have h : ∀ m : ZMod 240, m ^ 35 - m ^ 31 = 0 := by decide
  have hz : ((n ^ 35 - n ^ 31 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 35 - n ^ 31) 240).mp hz
  exact_mod_cast hdvd
