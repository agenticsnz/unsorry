import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_480_pow_24_sub_pow_sixteen (n : ℤ) : (480 : ℤ) ∣ n ^ 24 - n ^ 16 := by
  have h : ∀ m : ZMod 480, m ^ 24 - m ^ 16 = 0 := by decide
  have hz : ((n ^ 24 - n ^ 16 : ℤ) : ZMod 480) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 24 - n ^ 16) 480).mp hz
  exact_mod_cast hdvd
