import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-144-pow-sixteen-sub-pow-four`: `144 ∣ n^16 - n^4` over `ℤ`, by a finite `ZMod 144` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_144_pow_sixteen_sub_pow_four (n : ℤ) : (144 : ℤ) ∣ n ^ 16 - n ^ 4 := by
  have h : ∀ m : ZMod 144, m ^ 16 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 16 - n ^ 4 : ℤ) : ZMod 144) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 16 - n ^ 4) 144).mp hz
  exact_mod_cast hdvd
