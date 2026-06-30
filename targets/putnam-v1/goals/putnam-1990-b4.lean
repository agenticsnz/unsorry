import Mathlib

open Filter Topology Nat
abbrev putnam_1990_b4_solution : Prop := True

theorem putnam_1990_b4 : (∀ (G : Type*) (_ : Fintype G) (_ : Group G) (n : ℕ) (a b : G), (n = Fintype.card G ∧ G = Subgroup.closure {a, b} ∧ G ≠ Subgroup.closure {a} ∧ G ≠ Subgroup.closure {b}) → (∃ g : ℕ → G, (∀ x : G, {i : Fin (2 * n) | g i = x}.encard = 2)
  ∧ (∀ i : Fin (2 * n), (g ((i + 1) % (2 * n)) = g i * a) ∨ (g ((i + 1) % (2 * n)) = g i * b))) ↔ putnam_1990_b4_solution) := by
  sorry
