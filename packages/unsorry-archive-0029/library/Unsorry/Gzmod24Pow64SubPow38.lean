import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_64_sub_pow_38 (n : ℤ) : (24 : ℤ) ∣ n ^ 64 - n ^ 38 := by
  have h : ∀ m : ZMod 24, m ^ 64 - m ^ 38 = 0 := by decide
  have hz : ((n ^ 64 - n ^ 38 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 64 - n ^ 38) 24).mp hz
  exact_mod_cast hdvd
