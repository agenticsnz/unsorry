import Mathlib

open Topology Filter Polynomial Set

theorem putnam_2001_b1 (n : ℕ)
  (hn : n > 0) (hn' : Even n)
  (nums : Fin n → Fin n → ℤ)
  (colors : Fin n → Fin n → Fin 2)
  (hnums : ∀ k l, nums k l = k * n + l + 1)
  (hcolorsrows : ∀ k, (∑ l, (if (colors k l = 0) then 1 else 0)) = n / 2)
  (hcolorscols : ∀ l, (∑ k, (if (colors k l = 0) then 1 else 0)) = n / 2) :
  (∑ k, ∑ l, (if (colors k l = 0) then (nums k l) else 0)) = (∑ k, ∑ l, (if (colors k l = 1) then (nums k l) else 0)) := by
  sorry
