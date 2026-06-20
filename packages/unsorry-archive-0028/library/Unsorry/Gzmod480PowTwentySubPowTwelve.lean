import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_480_pow_twenty_sub_pow_twelve (n : ℤ) : (480 : ℤ) ∣ n ^ 20 - n ^ 12 := by
  have h : ∀ m : ZMod 480, m ^ 20 - m ^ 12 = 0 := by decide
  have hz : ((n ^ 20 - n ^ 12 : ℤ) : ZMod 480) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 20 - n ^ 12) 480).mp hz
  exact_mod_cast hdvd
