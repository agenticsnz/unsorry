import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-66-pow-fourteen-sub-pow-four`: `66 ∣ n^14 - n^4` over `ℤ`, by a finite `ZMod 66` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_66_pow_fourteen_sub_pow_four (n : ℤ) : (66 : ℤ) ∣ n ^ 14 - n ^ 4 := by
  have h : ∀ m : ZMod 66, m ^ 14 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 14 - n ^ 4 : ℤ) : ZMod 66) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 14 - n ^ 4) 66).mp hz
  exact_mod_cast hdvd
