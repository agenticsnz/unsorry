import Mathlib

set_option maxRecDepth 40000 in
/-- Goal `gzmod-255-pow-twentythree-sub-pow-seven`: `255 ∣ n^23 - n^7` over `ℤ`, by a finite `ZMod 255` case check
lifted through `ZMod.intCast_zmod_eq_zero_iff_dvd`. See `library/index/`. -/
theorem gzmod_255_pow_twentythree_sub_pow_seven (n : ℤ) : (255 : ℤ) ∣ n ^ 23 - n ^ 7 := by
  have h : ∀ m : ZMod 255, m ^ 23 - m ^ 7 = 0 := by decide
  have hz : ((n ^ 23 - n ^ 7 : ℤ) : ZMod 255) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n ^ 23 - n ^ 7) 255).mp hz
  exact_mod_cast hdvd
