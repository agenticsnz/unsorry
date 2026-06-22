import Mathlib

theorem platonic_pairs_realizable :
    ∀ pq ∈ ({(3, 3), (3, 4), (4, 3), (3, 5), (5, 3)} : Finset (ℕ × ℕ)),
      ∃ V E F : ℕ, 0 < V ∧ 0 < F ∧ pq.1 * F = 2 * E ∧ pq.2 * V = 2 * E ∧ V + F = E + 2 := by
  sorry
