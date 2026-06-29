import Mathlib

open Nat

theorem izho_2019_p1 : ((@Finset.univ 100!.Partition).filter
    (fun p => ∀ i ∈ p.parts, ∃ k ∈ Finset.Icc 1 99, i = Nat.factorial k)).card ≥ 100! := by
  sorry
