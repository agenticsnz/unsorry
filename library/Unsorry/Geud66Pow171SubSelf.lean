import Mathlib

set_option maxRecDepth 40000 in
theorem geud_66_pow_171_sub_self (n : ℤ) : (66 : ℤ) ∣ n ^ 171 - n := by
  have h : ∀ m : ZMod 66, m ^ 171 - m = 0 := by decide
  have hz : ((n ^ 171 - n : ℤ) : ZMod 66) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 171 - n) 66).mp hz
  exact_mod_cast hdvd
