import Mathlib

theorem putnam_1966_b4_pigeonhole (m n : ℕ) (S : Finset ℕ) (c : ℕ → ℕ) (hcard : S.card = m * n + 1) (hc : ∀ i ∈ S, c i ∈ Finset.Icc 1 n) : ∃ v ∈ Finset.Icc 1 n, m + 1 ≤ (S.filter (fun i => c i = v)).card := by
  sorry
