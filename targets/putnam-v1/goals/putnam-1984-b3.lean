import Mathlib

open Topology Filter Nat
abbrev putnam_1984_b3_solution : Prop := True

theorem putnam_1984_b3 : (∀ (F : Type*) (_ : Fintype F), Fintype.card F ≥ 2 → (∃ mul : F → F → F, ∀ x y z : F, (mul x z = mul y z → x = y) ∧ (mul x (mul y z) ≠ mul (mul x y) z))) ↔ putnam_1984_b3_solution := by
  sorry
