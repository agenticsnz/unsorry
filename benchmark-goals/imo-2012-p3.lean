import Mathlib

open scoped Finset
set_option autoImplicit false
structure AliceStrategy where
  N : ℕ
  x : Fin N
  nextAnswer : List (Set (Fin N) × Bool) → Set (Fin N) → Bool
structure BobStrategy where
  nextQuestion N : List (Set (Fin N) × Bool) → Set (Fin N)
  guess N : List (Set (Fin N) × Bool) → Finset (Fin N)
variable {k n : ℕ}
def history (A : AliceStrategy) (B : BobStrategy) : ℕ → List (Set (Fin A.N) × Bool)
  | 0 => []
  | t + 1 =>
    (B.nextQuestion A.N (history A B t),
      A.nextAnswer (history A B t) (B.nextQuestion A.N (history A B t)))
        :: history A B t
def AliceStrategy.IsValid (A : AliceStrategy) (B : BobStrategy) (k : ℕ) : Prop :=
  ∀ t₀ : ℕ, ∃ t ∈ Finset.Ico t₀ (t₀ + k),
    A.nextAnswer (history A B t) (B.nextQuestion A.N (history A B t))
      = (A.x ∈ B.nextQuestion A.N (history A B t))
def BobStrategy.IsValid (A : AliceStrategy) (B : BobStrategy) (n t : ℕ) : Prop :=
  #(B.guess A.N (history A B t)) ≤ n
def BobStrategy.IsWinning (B : BobStrategy) (k n : ℕ) : Prop :=
  ∀ (A : AliceStrategy), A.IsValid B k → ∃ t, B.IsValid A n t ∧ A.x ∈ B.guess A.N (history A B t)

theorem imo_2012_p3 :
    -- If `2 ^ k ≤ n`, then there exists a winning strategy for Bob.
    (∀ k n, 2 ^ k ≤ n → ∃ B : BobStrategy, B.IsWinning k n) ∧
    -- There exists a positive integer `k₀` such that for every `k ≥ k₀` there exists an integer
    -- `n ≥ 1.99 ^ k` such that no strategy for Bob is winning.
      ∃ k₀,
        ∀ k ≥ k₀,
          ∃ n : ℕ, n ≥ (1.99 : ℝ) ^ k ∧
            ∀ B : BobStrategy, ¬ B.IsWinning k n := by
  sorry
