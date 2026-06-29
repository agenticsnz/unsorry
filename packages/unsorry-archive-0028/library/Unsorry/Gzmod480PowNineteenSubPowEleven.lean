import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_480_pow_nineteen_sub_pow_eleven (n : ℤ) : (480 : ℤ) ∣ n ^ 19 - n ^ 11 := by
  have h : ∀ m : ZMod 480, m ^ 19 - m ^ 11 = 0 := by decide
  have hz : ((n ^ 19 - n ^ 11 : ℤ) : ZMod 480) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 19 - n ^ 11) 480).mp hz
  exact_mod_cast hdvd
