import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_480_pow_23_sub_pow_fifteen (n : ℤ) : (480 : ℤ) ∣ n ^ 23 - n ^ 15 := by
  have h : ∀ m : ZMod 480, m ^ 23 - m ^ 15 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 15 : ℤ) : ZMod 480) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 15) 480).mp hz
  exact_mod_cast hdvd
