import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_eighteen_sub_pow_four (n : ℤ) : (24 : ℤ) ∣ n ^ 18 - n ^ 4 := by
  have h : ∀ m : ZMod 24, m ^ 18 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 18 - n ^ 4 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 18 - n ^ 4) 24).mp hz
  exact_mod_cast hdvd
