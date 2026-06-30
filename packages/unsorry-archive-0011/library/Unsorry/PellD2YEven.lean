import Mathlib.Data.ZMod.Basic

theorem pell_d2_y_even (x y : ℤ) (h : x ^ 2 - 2 * y ^ 2 = 1) : Even (x * y) := by
  have h4 : (x : ZMod 4) ^ 2 - 2 * (y : ZMod 4) ^ 2 = 1 := by
    have hc := congrArg (Int.cast : ℤ → ZMod 4) h
    simpa using hc
  have h2 : ((x * y : ℤ) : ZMod 2) = 0 := by
    have key : ∀ a b : ZMod 4,
        a ^ 2 - 2 * b ^ 2 = 1 → (((a.val : ℤ) * (b.val : ℤ) : ℤ) : ZMod 2) = 0 := by
      decide
    simpa [ZMod.intCast_cast] using key (x : ZMod 4) (y : ZMod 4) h4
  have hdiv : (2 : ℤ) ∣ x * y := (ZMod.intCast_zmod_eq_zero_iff_dvd (x * y) 2).mp h2
  rcases hdiv with ⟨k, hk⟩
  exact ⟨k, by simpa [two_mul] using hk⟩
