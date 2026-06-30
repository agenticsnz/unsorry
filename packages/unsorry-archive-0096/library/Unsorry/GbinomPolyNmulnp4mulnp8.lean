import Mathlib

set_option maxRecDepth 40000 in
theorem gbinom_poly_nmulnp4mulnp8 (n : ℤ) : (3 : ℤ) ∣ (n * (n + 4) * (n + 8)) := by
  have h : ∀ m : ZMod 3, m * (m + 4) * (m + 8) = 0 := by decide
  have hz : ((n * (n + 4) * (n + 8) : ℤ) : ZMod 3) = 0 := by push_cast; exact h _
  have hdvd := (ZMod.intCast_zmod_eq_zero_iff_dvd (n * (n + 4) * (n + 8)) 3).mp hz
  exact_mod_cast hdvd
