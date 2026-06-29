import Mathlib

set_option maxRecDepth 40000 in
theorem gbinom_sp_0_2_3_5 (n : ℤ) : (8 : ℤ) ∣ (n * (n + 2) * (n + 3) * (n + 5)) := by
  have h : ∀ m : ZMod 8, m * (m + 2) * (m + 3) * (m + 5) = 0 := by decide
  have hz : ((n * (n + 2) * (n + 3) * (n + 5) : ℤ) : ZMod 8) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n + 2) * (n + 3) * (n + 5)) 8).mp hz
  exact_mod_cast hdvd
