import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_240_pow_seventeen_sub_pow_thirteen (n : ℤ) : (240 : ℤ) ∣ n ^ 17 - n ^ 13 := by
  have h : ∀ m : ZMod 240, m ^ 17 - m ^ 13 = 0 := by decide
  have hz : ((n ^ 17 - n ^ 13 : ℤ) : ZMod 240) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 17 - n ^ 13) 240).mp hz
  exact_mod_cast hdvd
