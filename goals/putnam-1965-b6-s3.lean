import Mathlib

theorem through_iff_mem_sphere (through : (ℝ × (EuclideanSpace ℝ (Fin 2))) → (EuclideanSpace ℝ (Fin 2)) → Prop) (through_def : through = fun (r, P) => fun Q => dist P Q = r) (r : ℝ) (P Q : EuclideanSpace ℝ (Fin 2)) : through (r, P) Q ↔ Q ∈ Metric.sphere P r := by
  sorry
