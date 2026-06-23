import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-51-pow-twenty-sub-pow-four`: `51 ∣ n^20 - n^4` over `ℤ`, by a finite `ZMod 51` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_51_pow_twenty_sub_pow_four (n : ℤ) : (51 : ℤ) ∣ n ^ 20 - n ^ 4 := by
  have h : ∀ m : ZMod 51, m ^ 20 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 20 - n ^ 4 : ℤ) : ZMod 51) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 20 - n ^ 4) 51).mp hz
  exact_mod_cast hdvd
