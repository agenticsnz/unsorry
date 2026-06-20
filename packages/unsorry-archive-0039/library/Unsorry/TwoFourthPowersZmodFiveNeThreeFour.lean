import Mathlib

theorem two_fourth_powers_zmod_five_ne_three_four (a b : ℤ) : ¬ (a ^ 4 + b ^ 4 ≡ 3 [ZMOD 5]) ∧ ¬ (a ^ 4 + b ^ 4 ≡ 4 [ZMOD 5]) := by
  have key : ∀ x y : ZMod 5, x ^ 4 + y ^ 4 ≠ 3 ∧ x ^ 4 + y ^ 4 ≠ 4 := by decide
  refine ⟨?_, ?_⟩
  · intro h
    have h5 : ((a ^ 4 + b ^ 4 : ℤ) : ZMod 5) = ((3 : ℤ) : ZMod 5) :=
      (ZMod.intCast_eq_intCast_iff _ _ _).mpr h
    push_cast at h5
    exact (key a b).1 h5
  · intro h
    have h5 : ((a ^ 4 + b ^ 4 : ℤ) : ZMod 5) = ((4 : ℤ) : ZMod 5) :=
      (ZMod.intCast_eq_intCast_iff _ _ _).mpr h
    push_cast at h5
    exact (key a b).2 h5