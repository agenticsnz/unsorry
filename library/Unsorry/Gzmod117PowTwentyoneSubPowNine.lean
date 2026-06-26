import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-117-pow-twentyone-sub-pow-nine`: `117 ∣ n^21 - n^9` over `ℤ`, by a finite `ZMod 117` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_117_pow_twentyone_sub_pow_nine (n : ℤ) : (117 : ℤ) ∣ n ^ 21 - n ^ 9 := by
  have h : ∀ m : ZMod 117, m ^ 21 - m ^ 9 = 0 := by decide
  have hz : ((n ^ 21 - n ^ 9 : ℤ) : ZMod 117) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 21 - n ^ 9) 117).mp hz
  exact_mod_cast hdvd
