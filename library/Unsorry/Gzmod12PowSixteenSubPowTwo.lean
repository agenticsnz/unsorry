import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_12_pow_sixteen_sub_pow_two (n : ℤ) : (12 : ℤ) ∣ n ^ 16 - n ^ 2 := by
  have h : ∀ m : ZMod 12, m ^ 16 - m ^ 2 = 0 := by decide
  have hz : ((n ^ 16 - n ^ 2 : ℤ) : ZMod 12) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 16 - n ^ 2) 12).mp hz
  exact_mod_cast hdvd
