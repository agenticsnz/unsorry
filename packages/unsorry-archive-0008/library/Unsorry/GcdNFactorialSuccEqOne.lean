import Mathlib

theorem gcd_n_factorial_succ_eq_one (n : ℕ) (h : 0 < n) : Nat.gcd n (Nat.factorial n + 1) = 1 := by
  have h1 : Nat.gcd n (Nat.factorial n + 1) ∣ n := Nat.gcd_dvd_left _ _
  have h2 : Nat.gcd n (Nat.factorial n + 1) ∣ (Nat.factorial n + 1) := Nat.gcd_dvd_right _ _
  have hnf : n ∣ Nat.factorial n := Nat.dvd_factorial h (le_refl n)
  have h3 : Nat.gcd n (Nat.factorial n + 1) ∣ Nat.factorial n := h1.trans hnf
  exact Nat.dvd_one.mp ((Nat.dvd_add_right h3).mp h2)
