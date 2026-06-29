import Mathlib

theorem two_of_three_sameSide (a b c d e : ℝ × ℝ) (hde : d ≠ e) (ha : a ∉ affineSpan ℝ ({d, e} : Set (ℝ × ℝ))) (hb : b ∉ affineSpan ℝ ({d, e} : Set (ℝ × ℝ))) (hc : c ∉ affineSpan ℝ ({d, e} : Set (ℝ × ℝ))) : (affineSpan ℝ ({d, e} : Set (ℝ × ℝ))).SSameSide a b ∨ (affineSpan ℝ ({d, e} : Set (ℝ × ℝ))).SSameSide a c ∨ (affineSpan ℝ ({d, e} : Set (ℝ × ℝ))).SSameSide b c := by
  sorry
