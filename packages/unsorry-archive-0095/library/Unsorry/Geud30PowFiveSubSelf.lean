import Mathlib

set_option maxRecDepth 40000 in
theorem geud_30_pow_five_sub_self (n : ℤ) : (30 : ℤ) ∣ n ^ 5 - n := by
  have h : ∀ m : ZMod 30, m ^ 5 - m = 0 := by decide
  have hz : ((n ^ 5 - n : ℤ) : ZMod 30) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 5 - n) 30).mp hz
  exact_mod_cast hdvd
