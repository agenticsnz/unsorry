import Mathlib

open scoped Finset

theorem imo2021p6 {m : ℕ} (hm : 2 ≤ m) (A : Finset ℤ) (B : Fin m → Finset ℤ) (hBA : ∀ i, B i ⊆ A)
    (hB : ∀ k, ∑ i ∈ B k, i = m ^ ((k : ℕ) + 1)) : (m : ℚ) / 2 ≤ #A := by
  sorry
