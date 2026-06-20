import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-132-pow-seventeen-sub-pow-seven`: `132 ∣ n^17 - n^7` over `ℤ`, by a finite `ZMod 132` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_132_pow_seventeen_sub_pow_seven (n : ℤ) : (132 : ℤ) ∣ n ^ 17 - n ^ 7 := by
  have h : ∀ m : ZMod 132, m ^ 17 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 17 - n ^ 7 : ℤ) : ZMod 132) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 17 - n ^ 7) 132).mp hz
  exact_mod_cast hdvd
