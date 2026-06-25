import Mathlib

theorem power_of_point_const_along_chord (A B X P1 P2 : EuclideanSpace ℝ (Fin 2)) (r1 r2 : ℝ) (hAB : A ≠ B) (hX : Collinear ℝ ({X, A, B} : Set (EuclideanSpace ℝ (Fin 2)))) (hP1A : dist P1 A = r1) (hP1B : dist P1 B = r1) (hP2A : dist P2 A = r2) (hP2B : dist P2 B = r2) : dist X P1 ^ 2 - r1 ^ 2 = dist X P2 ^ 2 - r2 ^ 2 := by
  sorry
