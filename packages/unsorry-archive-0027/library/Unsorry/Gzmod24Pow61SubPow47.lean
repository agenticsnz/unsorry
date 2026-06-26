import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_24_pow_61_sub_pow_47 (n : ℤ) : (24 : ℤ) ∣ n ^ 61 - n ^ 47 := by
  have h : ∀ m : ZMod 24, m ^ 61 - m ^ 47 = 0 := by decide
  have hz : ((n ^ 61 - n ^ 47 : ℤ) : ZMod 24) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 61 - n ^ 47) 24).mp hz
  exact_mod_cast hdvd
