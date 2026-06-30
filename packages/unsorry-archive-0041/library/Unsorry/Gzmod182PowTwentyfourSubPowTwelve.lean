import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-182-pow-twentyfour-sub-pow-twelve`: `182 ∣ n^24 - n^12` over `ℤ`, by a finite `ZMod 182` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_182_pow_twentyfour_sub_pow_twelve (n : ℤ) : (182 : ℤ) ∣ n ^ 24 - n ^ 12 := by
  have h : ∀ m : ZMod 182, m ^ 24 - m ^ 12 = 0 := by decide
  have hz : ((n ^ 24 - n ^ 12 : ℤ) : ZMod 182) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 24 - n ^ 12) 182).mp hz
  exact_mod_cast hdvd
