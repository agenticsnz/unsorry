import Mathlib

open Topology Filter Function Nat
abbrev putnam_1984_a6_solution : ℕ := 4

theorem putnam_1984_a6 (f : ℕ → ℕ)
    (hf : ∀ n, some (f n) = (Nat.digits 10 (n !)).find? (fun d ↦ d ≠ 0))
    (IsPeriodicFrom : ℕ → (ℕ → ℕ) → ℕ → Prop)
    (IsPeriodicFrom_def : ∀ x f p, IsPeriodicFrom x f p ↔ Periodic (f ∘ (· + x)) p)
    (P : ℕ → (ℕ → ℕ) → ℕ → Prop)
    (P_def : ∀ x g p, P x g p ↔ if p = 0 then (∀ q > 0, ¬ IsPeriodicFrom x g q) else
        IsLeast {q | 0 < q ∧ IsPeriodicFrom x g q} p) :
    ∃ g : ℕ → ℕ,
      (∀ᵉ (k > 0) (a : Fin k → ℕ) (ha : Injective a), f (∑ i, 5 ^ (a i)) = g (∑ i, a i)) ∧
      P 1 g putnam_1984_a6_solution := by
  sorry
