import Mathlib

abbrev S (n : ℕ) : Finset ℕ :=
  {m < 10^n | (Nat.digits 10 m).length = n ∧
  (∀ i : Fin (Nat.digits 10 m).length, Odd ((Nat.digits 10 m).get i)) ∧
  Even ((Nat.digits 10 m).count 1) ∧ Even ((Nat.digits 10 m).count 3) ∧
  ((Nat.digits 10 m).count 1) ≠ 0 ∧ ((Nat.digits 10 m).count 3) ≠ 0}

theorem brualdi_ch7_27 (n : ℕ) : (S n).card = ((fun n => (5 ^ n - 4 ^ (n + 1) + 6 * 3 ^ n - 4 * 2 ^ n + 1) / 4 ) : ℕ → ℕ ) n := by
  sorry
