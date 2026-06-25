import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-133-pow-twentyseven-sub-pow-nine`: `133 ∣ n^27 - n^9` over `ℤ`, by a finite `ZMod 133` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_133_pow_twentyseven_sub_pow_nine (n : ℤ) : (133 : ℤ) ∣ n ^ 27 - n ^ 9 := by
  have h : ∀ m : ZMod 133, m ^ 27 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 27 - n ^ 9 : ℤ) : ZMod 133) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 27 - n ^ 9) 133).mp hz
  exact_mod_cast hdvd
