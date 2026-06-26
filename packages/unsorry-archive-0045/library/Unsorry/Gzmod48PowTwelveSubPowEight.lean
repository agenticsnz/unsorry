import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-48-pow-twelve-sub-pow-eight`: `48 ∣ n^12 - n^8` over `ℤ`, by a finite `ZMod 48` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_48_pow_twelve_sub_pow_eight (n : ℤ) : (48 : ℤ) ∣ n ^ 12 - n ^ 8 := by
  have h : ∀ m : ZMod 48, m ^ 12 - m ^ 8 = 0 := by decide
  have hz : ((n ^ 12 - n ^ 8 : ℤ) : ZMod 48) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 12 - n ^ 8) 48).mp hz
  exact_mod_cast hdvd
