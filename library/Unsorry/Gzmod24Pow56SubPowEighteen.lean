import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_56_sub_pow_eighteen (n : ℤ) : (24 : ℤ) ∣ n ^ 56 - n ^ 18 := by
  have h : ∀ m : ZMod 24, m ^ 56 - m ^ 18 = 0 := by decide
  have hz : ((n ^ 56 - n ^ 18 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 56 - n ^ 18) 24).mp hz
  exact_mod_cast hdvd
