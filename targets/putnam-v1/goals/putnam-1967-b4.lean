import Mathlib

open Nat Topology Filter

theorem putnam_1967_b4 (n : ℕ)
(lockers : ℕ → Set.Icc 1 n → Bool)
(npos : n ≥ 1)
(hlockers0 : ∀ i : Set.Icc 1 n, lockers 0 i = false)
(hlockersk : ∀ k ∈ Set.Icc 1 n, ∀ i : Set.Icc 1 n, lockers k i = if k ∣ i then !(lockers (k - 1) i) else (lockers (k - 1) i))
: ∀ i : Set.Icc 1 n, lockers n i ↔ (∃ j : ℤ, j ^ 2 = i) := by
  sorry
