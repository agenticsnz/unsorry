import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-204-pow-twentyone-sub-pow-five`: `204 ∣ n^21 - n^5` over `ℤ`, by a finite `ZMod 204` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_204_pow_twentyone_sub_pow_five (n : ℤ) : (204 : ℤ) ∣ n ^ 21 - n ^ 5 := by
  have h : ∀ m : ZMod 204, m ^ 21 - m ^ 5 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 5 : ℤ) : ZMod 204) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 5) 204).mp hz
  exact_mod_cast hdvd
