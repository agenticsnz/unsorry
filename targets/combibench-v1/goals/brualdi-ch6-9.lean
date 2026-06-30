import Mathlib

open Finset

theorem brualdi_ch6_9 : {x : Fin 4 → ℕ | ∑ i, x i = 20 ∧ x 0 ∈ Icc 1 6 ∧ x 1 ∈ Icc 0 7 ∧
    x 2 ∈ Icc 4 8 ∧ x 3 ∈ Icc 2 6}.ncard = ((96) : ℕ ) := by
  sorry
