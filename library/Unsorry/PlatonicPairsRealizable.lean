import Mathlib

theorem platonic_pairs_realizable :
    ∀ pq ∈ ({(3, 3), (3, 4), (4, 3), (3, 5), (5, 3)} : Finset (ℕ × ℕ)),
      ∃ V E F : ℕ, 0 < V ∧ 0 < F ∧ pq.1 * F = 2 * E ∧ pq.2 * V = 2 * E ∧ V + F = E + 2 := by
  intro pq hpq
  fin_cases hpq
  · exact ⟨4, 6, 4, by decide, by decide, by decide, by decide, by decide⟩
  · exact ⟨6, 12, 8, by decide, by decide, by decide, by decide, by decide⟩
  · exact ⟨8, 12, 6, by decide, by decide, by decide, by decide, by decide⟩
  · exact ⟨12, 30, 20, by decide, by decide, by decide, by decide, by decide⟩
  · exact ⟨20, 30, 12, by decide, by decide, by decide, by decide, by decide⟩