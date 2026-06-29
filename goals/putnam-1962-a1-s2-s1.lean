import Mathlib

theorem noncollinear_not_mem_line (d e x : ℝ × ℝ) (h : ¬ Collinear ℝ ({d, e, x} : Set (ℝ × ℝ))) : x ∉ affineSpan ℝ ({d, e} : Set (ℝ × ℝ)) := by
  sorry
