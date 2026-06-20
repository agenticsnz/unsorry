import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_480_pow_fifteen_sub_pow_seven (n : ℤ) : (480 : ℤ) ∣ n ^ 15 - n ^ 7 := by
  have h : ∀ m : ZMod 480, m ^ 15 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 15 - n ^ 7 : ℤ) : ZMod 480) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 15 - n ^ 7) 480).mp hz
  exact_mod_cast hdvd
