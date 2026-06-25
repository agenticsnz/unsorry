import Mathlib

theorem putnam_1967_a5_centsymm_subset_closedBall (K : Set (EuclideanSpace ℝ (Fin 2))) (hsymm : ∀ x ∈ K, -x ∈ K) (hd : ∀ P ∈ K, ∀ Q ∈ K, dist P Q ≤ 1) : K ⊆ Metric.closedBall 0 (1/2) := by
  sorry
