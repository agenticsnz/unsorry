import Mathlib

open Set Filter Topology Real Polynomial Function

theorem putnam_1985_b6 (n : ℕ)
(npos : n > 0)
(G : Finset (Matrix (Fin n) (Fin n) ℝ))
(groupG : (∀ g ∈ G, ∀ h ∈ G, g * h ∈ G) ∧ 1 ∈ G ∧ (∀ g ∈ G, ∃ h ∈ G, g * h = 1))
(hG : ∑ M ∈ G, Matrix.trace M = 0)
: (∑ M ∈ G, M = 0) := by
  sorry
