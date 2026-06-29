import Mathlib

theorem quartic_plus_four_not_prime (n : ℤ) (hn : 2 ≤ n) : ¬ Prime (n ^ 4 + 4) := by
  intro hp
  have hirr : Irreducible (n ^ 4 + 4) := hp.irreducible
  have hfac : n ^ 4 + 4 = (n ^ 2 - 2 * n + 2) * (n ^ 2 + 2 * n + 2) := by ring
  have ha : (2 : ℤ) ≤ n ^ 2 - 2 * n + 2 := by nlinarith [sq_nonneg (n - 1)]
  have hb : (2 : ℤ) ≤ n ^ 2 + 2 * n + 2 := by nlinarith [sq_nonneg (n + 1)]
  rcases hirr.isUnit_or_isUnit hfac with h | h
  · rcases Int.isUnit_iff.mp h with h1 | h1 <;> omega
  · rcases Int.isUnit_iff.mp h with h1 | h1 <;> omega