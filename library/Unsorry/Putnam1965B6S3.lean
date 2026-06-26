import Mathlib.Analysis.InnerProductSpace.PiL2

/-!
# Putnam 1965 B6 (sub-goal 3)

A point `Q` lies on the circle of radius `r` centred at `P` exactly when it belongs
to `Metric.sphere P r`. This unfolds the predicate `through` and matches the two
formulations up to commutativity of the distance.
-/

theorem through_iff_mem_sphere (through : (ℝ × (EuclideanSpace ℝ (Fin 2))) → (EuclideanSpace ℝ (Fin 2)) → Prop) (through_def : through = fun (r, P) => fun Q => dist P Q = r) (r : ℝ) (P Q : EuclideanSpace ℝ (Fin 2)) : through (r, P) Q ↔ Q ∈ Metric.sphere P r := by
  subst through_def
  show dist P Q = r ↔ Q ∈ Metric.sphere P r
  rw [Metric.mem_sphere, dist_comm]
