import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-80-pow-twelve-sub-pow-four`: `80 ∣ n^12 - n^4` over `ℤ`, by a finite `ZMod 80` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_80_pow_twelve_sub_pow_four (n : ℤ) : (80 : ℤ) ∣ n ^ 12 - n ^ 4 := by
  have h : ∀ m : ZMod 80, m ^ 12 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 12 - n ^ 4 : ℤ) : ZMod 80) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 12 - n ^ 4) 80).mp hz
  exact_mod_cast hdvd
