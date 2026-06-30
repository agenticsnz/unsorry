import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_480_pow_sixteen_sub_pow_eight (n : ℤ) : (480 : ℤ) ∣ n ^ 16 - n ^ 8 := by
  have h : ∀ m : ZMod 480, m ^ 16 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 16 - n ^ 8 : ℤ) : ZMod 480) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 16 - n ^ 8) 480).mp hz
  exact_mod_cast hdvd
