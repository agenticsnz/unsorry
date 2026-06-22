import Mathlib

set_option maxRecDepth 40000 in
theorem gzmod_66_pow_51_sub_pow_one (n : ℤ) : (66 : ℤ) ∣ n ^ 51 - n ^ 1 := by
  have h : ∀ m : ZMod 66, m ^ 51 - m ^ 1 = 0 := by decide
  have hz : ((n ^ 51 - n ^ 1 : ℤ) : ZMod 66) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 51 - n ^ 1) 66).mp hz
  exact_mod_cast hdvd
