import Mathlib

theorem diff_two_cubes_zmod_seven_ne_three_four (a b : ℤ) :
    ¬ ((7 : ℤ) ∣ (a ^ 3 - b ^ 3 - 3)) ∧ ¬ ((7 : ℤ) ∣ (a ^ 3 - b ^ 3 - 4)) := by
  have key3 : ∀ u v : ZMod 7, u ^ 3 - v ^ 3 - 3 ≠ 0 := by decide
  have key4 : ∀ u v : ZMod 7, u ^ 3 - v ^ 3 - 4 ≠ 0 := by decide
  refine ⟨fun hd => ?_, fun hd => ?_⟩
  · have hz : ((a ^ 3 - b ^ 3 - 3 : ℤ) : ZMod 7) = 0 := by
      rw [ZMod.intCast_zmod_eq_zero_iff_dvd]; exact_mod_cast hd
    push_cast at hz
    exact key3 (a : ZMod 7) (b : ZMod 7) hz
  · have hz : ((a ^ 3 - b ^ 3 - 4 : ℤ) : ZMod 7) = 0 := by
      rw [ZMod.intCast_zmod_eq_zero_iff_dvd]; exact_mod_cast hd
    push_cast at hz
    exact key4 (a : ZMod 7) (b : ZMod 7) hz
