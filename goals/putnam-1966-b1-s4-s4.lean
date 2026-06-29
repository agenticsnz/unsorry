import Mathlib

theorem putnam_1966_b1_proj_y_upvar_le_vertex_diff (n : ℕ) (hn : n ≥ 3) (L : ZMod n → EuclideanSpace ℝ (Fin 2)) (hsq : ∀ i : ZMod n, L i 0 ∈ Set.Icc 0 1 ∧ L i 1 ∈ Set.Icc 0 1) (hnoncol : ∀ i j k : ZMod n, i ≠ j ∧ j ≠ k ∧ k ≠ i → ¬Collinear ℝ {L i, L j, L k}) (hconvex : ∀ i : ZMod n, segment ℝ (L i) (L (i + 1)) ∩ interior (convexHull ℝ {L j | j : ZMod n}) = ∅) : ∃ a b : ZMod n, ∑ i : Fin n, max (L (i + 1) 1 - L i 1) 0 ≤ L a 1 - L b 1 := by
  sorry
