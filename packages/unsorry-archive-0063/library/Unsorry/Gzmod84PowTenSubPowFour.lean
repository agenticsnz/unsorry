import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-84-pow-ten-sub-pow-four`: `84 ∣ n^10 - n^4` over `ℤ`, by a finite `ZMod 84` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_84_pow_ten_sub_pow_four (n : ℤ) : (84 : ℤ) ∣ n ^ 10 - n ^ 4 := by
  have h : ∀ m : ZMod 84, m ^ 10 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 10 - n ^ 4 : ℤ) : ZMod 84) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 10 - n ^ 4) 84).mp hz
  exact_mod_cast hdvd
