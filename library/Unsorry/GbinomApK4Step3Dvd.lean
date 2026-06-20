import Mathlib

set_option maxRecDepth 40000 in
theorem gbinom_ap_k4_step3_dvd (n : ℤ) : (8 : ℤ) ∣ (n * (n + 3) * (n + 6) * (n + 9)) := by
  have h : ∀ m : ZMod 8, m * (m + 3) * (m + 6) * (m + 9) = 0 := by decide
  have hz : ((n * (n + 3) * (n + 6) * (n + 9) : ℤ) : ZMod 8) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n + 3) * (n + 6) * (n + 9)) 8).mp hz
  exact_mod_cast hdvd
