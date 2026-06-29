import Mathlib

theorem imosl_2019_c2 (n : ℕ) (blocks : Fin n → ℝ) (h1 : ∀ i, blocks i ≥ 1)
    (h2 : ∑ i, blocks i = 2 * n) :
    ∀ r : ℝ, 0 ≤ r ∧ r ≤ 2 * n - 2 →
      ∃ (s : Finset (Fin n)), (∑ i ∈ s, blocks i) ≥ r ∧ (∑ i ∈ s, blocks i) ≤ r + 2 := by
  sorry
