import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-57-pow-twentyfour-sub-pow-six`: `57 ∣ n^24 - n^6` over `ℤ`, by a finite `ZMod 57` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_57_pow_twentyfour_sub_pow_six (n : ℤ) : (57 : ℤ) ∣ n ^ 24 - n ^ 6 := by
  have h : ∀ m : ZMod 57, m ^ 24 - m ^ 6 = 0 := by decide
  have hz : ((n ^ 24 - n ^ 6 : ℤ) : ZMod 57) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 24 - n ^ 6) 57).mp hz
  exact_mod_cast hdvd
