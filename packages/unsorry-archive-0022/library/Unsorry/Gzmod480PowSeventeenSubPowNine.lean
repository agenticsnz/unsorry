import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_480_pow_seventeen_sub_pow_nine (n : ℤ) : (480 : ℤ) ∣ n ^ 17 - n ^ 9 := by
  have h : ∀ m : ZMod 480, m ^ 17 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 17 - n ^ 9 : ℤ) : ZMod 480) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 17 - n ^ 9) 480).mp hz
  exact_mod_cast hdvd
