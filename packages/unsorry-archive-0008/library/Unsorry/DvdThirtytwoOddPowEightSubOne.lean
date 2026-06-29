import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_thirtytwo_odd_pow_eight_sub_one (n : ℤ) (hn : Odd n) : (32 : ℤ) ∣ n ^ 8 - 1 := by
  obtain ⟨k, rfl⟩ := hn
  have key : ∀ m : ZMod 32, (2 * m + 1) ^ 8 - 1 = 0 := by decide
  have h : ((((2 * k + 1) ^ 8 - 1 : ℤ)) : ZMod 32) = 0 := by
    push_cast
    exact key (k : ZMod 32)
  rwa [ZMod.intCast_zmod_eq_zero_iff_dvd] at h