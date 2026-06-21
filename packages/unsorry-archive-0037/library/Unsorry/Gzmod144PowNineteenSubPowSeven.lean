import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-144-pow-nineteen-sub-pow-seven`: `144 ∣ n^19 - n^7` over `ℤ`, by a finite `ZMod 144` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_144_pow_nineteen_sub_pow_seven (n : ℤ) : (144 : ℤ) ∣ n ^ 19 - n ^ 7 := by
  have h : ∀ m : ZMod 144, m ^ 19 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 19 - n ^ 7 : ℤ) : ZMod 144) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 19 - n ^ 7) 144).mp hz
  exact_mod_cast hdvd
