import Mathlib.Data.ZMod.Basic

theorem no_int_sq_eq_eight_mul_add_three (n : ℤ) : ¬ ∃ m : ℤ, m ^ 2 = 8 * n + 3 := by
  rintro ⟨m, hm⟩
  have hdvd : (8 : ℤ) ∣ (m ^ 2 - 3) := ⟨n, by omega⟩
  have h0 : ((m ^ 2 - 3 : ℤ) : ZMod 8) = 0 := by
    rw [ZMod.intCast_zmod_eq_zero_iff_dvd]
    exact_mod_cast hdvd
  push_cast at h0
  have key : ∀ x : ZMod 8, x ^ 2 - 3 ≠ 0 := by decide
  exact key _ h0
