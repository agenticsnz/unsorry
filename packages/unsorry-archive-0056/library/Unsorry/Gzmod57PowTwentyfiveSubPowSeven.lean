import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-57-pow-twentyfive-sub-pow-seven`: `57 ∣ n^25 - n^7` over `ℤ`, by a finite `ZMod 57` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_57_pow_twentyfive_sub_pow_seven (n : ℤ) : (57 : ℤ) ∣ n ^ 25 - n ^ 7 := by
  have h : ∀ m : ZMod 57, m ^ 25 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 25 - n ^ 7 : ℤ) : ZMod 57) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 25 - n ^ 7) 57).mp hz
  exact_mod_cast hdvd
