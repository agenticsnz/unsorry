import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_480_pow_21_sub_pow_thirteen (n : ℤ) : (480 : ℤ) ∣ n ^ 21 - n ^ 13 := by
  have h : ∀ m : ZMod 480, m ^ 21 - m ^ 13 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 13 : ℤ) : ZMod 480) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 13) 480).mp hz
  exact_mod_cast hdvd
