import Mathlib

theorem gcd_quad_factored_n1_eq_n1 (n : ℕ) : Nat.gcd (n ^ 2 + 3 * n + 2) (n + 1) = n + 1 := by
  have hdvd : (n + 1) ∣ (n ^ 2 + 3 * n + 2) := ⟨n + 2, by ring⟩
  exact Nat.gcd_eq_right hdvd
