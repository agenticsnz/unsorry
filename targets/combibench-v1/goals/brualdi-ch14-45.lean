import Mathlib

theorem brualdi_ch14_45 {n : ℕ} (h : Odd n) (hp : Nat.Prime n) :
    ∀ i ∈ Finset.Icc 1 n, ((finRotate n) ^ i).IsCycle := by
  sorry
