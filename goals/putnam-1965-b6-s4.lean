import Mathlib

theorem not_collinear_not_concyclic_exists_separated_circles (A B C D : EuclideanSpace ℝ (Fin 2)) (hncol : ¬ Collinear ℝ ({A, B, C, D} : Set (EuclideanSpace ℝ (Fin 2)))) (hncon : ¬ ∃ (r : ℝ) (P : EuclideanSpace ℝ (Fin 2)), dist P A = r ∧ dist P B = r ∧ dist P C = r ∧ dist P D = r) : ∃ (r s : ℝ) (P Q : EuclideanSpace ℝ (Fin 2)), dist P A = r ∧ dist P B = r ∧ dist Q C = s ∧ dist Q D = s ∧ ¬ (Metric.sphere P r ∩ Metric.sphere Q s).Nonempty := by
  sorry
