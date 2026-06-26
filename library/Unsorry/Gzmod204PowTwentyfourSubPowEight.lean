import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-204-pow-twentyfour-sub-pow-eight`: `204 ∣ n^24 - n^8` over `ℤ`, by a finite `ZMod 204` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_204_pow_twentyfour_sub_pow_eight (n : ℤ) : (204 : ℤ) ∣ n ^ 24 - n ^ 8 := by
  have h : ∀ m : ZMod 204, m ^ 24 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 24 - n ^ 8 : ℤ) : ZMod 204) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 24 - n ^ 8) 204).mp hz
  exact_mod_cast hdvd
