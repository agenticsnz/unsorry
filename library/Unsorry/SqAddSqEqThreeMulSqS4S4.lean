import Mathlib.Data.Int.Basic

theorem int_triple_not_nonzero_or_iff_zero (x y z : ℤ) :
    ¬ (x ≠ 0 ∨ y ≠ 0 ∨ z ≠ 0) ↔ x = 0 ∧ y = 0 ∧ z = 0 := by
  constructor
  · intro h
    refine ⟨?_, ?_, ?_⟩
    · by_contra hx
      exact h (Or.inl hx)
    · by_contra hy
      exact h (Or.inr (Or.inl hy))
    · by_contra hz
      exact h (Or.inr (Or.inr hz))
  · intro h hnz
    cases hnz with
    | inl hx => exact hx h.1
    | inr hyz =>
        cases hyz with
        | inl hy => exact hy h.2.1
        | inr hz => exact hz h.2.2
