import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-255-pow-twentysix-sub-pow-ten`: `255 ∣ n^26 - n^10` over `ℤ`, by a finite `ZMod 255` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_255_pow_twentysix_sub_pow_ten (n : ℤ) : (255 : ℤ) ∣ n ^ 26 - n ^ 10 := by
  have h : ∀ m : ZMod 255, m ^ 26 - m ^ 10 = 0 := by decide
  have hz : ((n ^ 26 - n ^ 10 : ℤ) : ZMod 255) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 26 - n ^ 10) 255).mp hz
  exact_mod_cast hdvd
