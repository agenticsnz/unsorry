import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-68-pow-twenty-sub-pow-four`: `68 ∣ n^20 - n^4` over `ℤ`, by a finite `ZMod 68` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_68_pow_twenty_sub_pow_four (n : ℤ) : (68 : ℤ) ∣ n ^ 20 - n ^ 4 := by
  have h : ∀ m : ZMod 68, m ^ 20 - m ^ 4 = 0 := by decide
  have hz : ((n ^ 20 - n ^ 4 : ℤ) : ZMod 68) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 20 - n ^ 4) 68).mp hz
  exact_mod_cast hdvd
