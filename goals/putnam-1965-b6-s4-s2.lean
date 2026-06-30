import Mathlib

theorem exists_equidistant_point_of_directions_linearIndependent (A B C D : EuclideanSpace ℝ (Fin 2)) (h : LinearIndependent ℝ ![B - A, D - C]) : ∃ O : EuclideanSpace ℝ (Fin 2), dist O A = dist O B ∧ dist O C = dist O D := by
  sorry
