import Mathlib

theorem exists_three_proper_subgroups_cover_univ : ∃ H : Fin 3 → Subgroup (Multiplicative (ZMod 2 × ZMod 2)), (∀ i, H i < ⊤) ∧ ⋃ i, (H i : Set (Multiplicative (ZMod 2 × ZMod 2))) = Set.univ := by
  sorry
