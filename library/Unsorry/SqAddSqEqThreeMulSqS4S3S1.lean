import Mathlib.Data.Int.Basic

theorem pos_natAbs_sum_imp_nonzero (x y z : ℤ) :
    0 < Int.natAbs x + Int.natAbs y + Int.natAbs z → x ≠ 0 ∨ y ≠ 0 ∨ z ≠ 0 := by
  intro h
  by_cases hx : x = 0
  · by_cases hy : y = 0
    · by_cases hz : z = 0
      · simp [hx, hy, hz] at h
      · exact Or.inr (Or.inr hz)
    · exact Or.inr (Or.inl hy)
  · exact Or.inl hx
