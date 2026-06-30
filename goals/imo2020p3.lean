import Mathlib

open scoped Finset

theorem imo2020p3 {n : ℕ} {c : Fin (4 * n) → Fin n} (h : ∀ i, #{j | c j = i} = 4) :
    ∃ S : Finset (Fin (4 * n)), ∑ i ∈ S, ((i : ℕ) + 1) = ∑ i ∈ Sᶜ, ((i : ℕ) + 1) ∧
      ∀ i, #{j ∈ S | c j = i} = 2 := by
  sorry
