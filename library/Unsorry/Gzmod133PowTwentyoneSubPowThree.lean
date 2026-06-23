import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-133-pow-twentyone-sub-pow-three`: `133 ∣ n^21 - n^3` over `ℤ`, by a finite `ZMod 133` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_133_pow_twentyone_sub_pow_three (n : ℤ) : (133 : ℤ) ∣ n ^ 21 - n ^ 3 := by
  have h : ∀ m : ZMod 133, m ^ 21 - m ^ 3 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 3 : ℤ) : ZMod 133) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 3) 133).mp hz
  exact_mod_cast hdvd
