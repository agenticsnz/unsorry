import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_eighteen_sub_pow_fourteen (n : ℤ) : (240 : ℤ) ∣ n ^ 18 - n ^ 14 := by
  have h : ∀ m : ZMod 240, m ^ 18 - m ^ 14 = 0 := by decide
  have hz : ((n ^ 18 - n ^ 14 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 18 - n ^ 14) 240).mp hz
  exact_mod_cast hdvd
