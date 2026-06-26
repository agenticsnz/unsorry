import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-72-pow-ten-sub-pow-four`: `72 ∣ n^10 - n^4` over `ℤ`, by a finite `ZMod 72` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_72_pow_ten_sub_pow_four (n : ℤ) : (72 : ℤ) ∣ n ^ 10 - n ^ 4 := by
  have h : ∀ m : ZMod 72, m ^ 10 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 10 - n ^ 4 : ℤ) : ZMod 72) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 10 - n ^ 4) 72).mp hz
  exact_mod_cast hdvd
