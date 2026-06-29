import Mathlib

open Set Filter Topology

theorem putnam_1988_b4 (a : ℕ → ℝ)
    (IsPosConv : (ℕ → ℝ) → Prop)
    (IsPosConv_def : ∀ a' : ℕ → ℝ, IsPosConv a' ↔
      (∀ n ≥ 1, a' n > 0) ∧
      (∃ s : ℝ, Tendsto (fun N : ℕ => ∑ n : Set.Icc 1 N, a' n) atTop (𝓝 s))) :
    (IsPosConv a) → IsPosConv (fun n : ℕ => (a n) ^ ((n : ℝ) / (n + 1))) := by
  sorry
