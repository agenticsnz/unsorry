import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-171-pow-twentyseven-sub-pow-nine`: `171 ∣ n^27 - n^9` over `ℤ`, by a finite `ZMod 171` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_171_pow_twentyseven_sub_pow_nine (n : ℤ) : (171 : ℤ) ∣ n ^ 27 - n ^ 9 := by
  have h : ∀ m : ZMod 171, m ^ 27 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 27 - n ^ 9 : ℤ) : ZMod 171) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 27 - n ^ 9) 171).mp hz
  exact_mod_cast hdvd
