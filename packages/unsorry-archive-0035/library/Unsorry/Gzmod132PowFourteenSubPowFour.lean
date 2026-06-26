import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-132-pow-fourteen-sub-pow-four`: `132 ∣ n^14 - n^4` over `ℤ`, by a finite `ZMod 132` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_132_pow_fourteen_sub_pow_four (n : ℤ) : (132 : ℤ) ∣ n ^ 14 - n ^ 4 := by
  have h : ∀ m : ZMod 132, m ^ 14 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 14 - n ^ 4 : ℤ) : ZMod 132) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 4) 132).mp hz
  exact_mod_cast hdvd
