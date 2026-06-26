import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-520-pow-sixteen-sub-pow-four`: `520 ∣ n^16 - n^4` over `ℤ`, by a finite `ZMod 520` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_520_pow_sixteen_sub_pow_four (n : ℤ) : (520 : ℤ) ∣ n ^ 16 - n ^ 4 := by
  have h : ∀ m : ZMod 520, m ^ 16 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 16 - n ^ 4 : ℤ) : ZMod 520) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 16 - n ^ 4) 520).mp hz
  exact_mod_cast hdvd
