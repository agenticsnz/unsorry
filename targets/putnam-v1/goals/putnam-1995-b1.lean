import Mathlib

open Filter Topology Real Nat

theorem putnam_1995_b1 (Pi : Finpartition (Finset.range 9) → (Finset.range 9) → ℕ)
  (Pi_def : ∀ partition k, Pi partition k = (Exists.choose (Finpartition.exists_mem partition k.2)).card) :
  ∀ Pt1 Pt2,
    ∃ x y : Finset.range 9,
      x ≠ y ∧
      Pi Pt1 x = Pi Pt1 y ∧
      Pi Pt2 x = Pi Pt2 y := by
  sorry
