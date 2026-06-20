import Mathlib

set_option maxRecDepth 40000 in
theorem gbinom_ap_k6_step2_dvd (n : ℤ) : (45 : ℤ) ∣ (n * (n + 2) * (n + 4) * (n + 6) * (n + 8) * (n + 10)) := by
  have h : ∀ m : ZMod 45, m * (m + 2) * (m + 4) * (m + 6) * (m + 8) * (m + 10) = 0 := by decide
  have hz : ((n * (n + 2) * (n + 4) * (n + 6) * (n + 8) * (n + 10) : ℤ) : ZMod 45) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n + 2) * (n + 4) * (n + 6) * (n + 8) * (n + 10)) 45).mp hz
  exact_mod_cast hdvd
