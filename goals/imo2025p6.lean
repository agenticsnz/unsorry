import Mathlib

open scoped Finset Function
abbrev Cell : Type := Fin 2025 × Fin 2025
structure Tile where
  lowerLeft : Cell
  upperRight : Cell
  below_left : lowerLeft ≤ upperRight
def Tile.cells (t : Tile) : Set Cell := Set.Icc t.lowerLeft t.upperRight
def answer : ℕ := sorry

theorem imo2025p6 :
    IsLeast {k : ℕ | ∃ tiles : Fin k → Tile,
      Pairwise (Disjoint on (fun i ↦ (tiles i).cells)) ∧
      ∃ e : Fin 2025 ≃ Fin 2025, (⋃ i, (tiles i).cells)ᶜ = Set.range fun i ↦ (i, e i)} answer := by
  sorry
