import Mathlib

theorem two_squares_zmod_sixteen_ne_three_seven_eleven (a b : ℤ) :
    (a^2 + b^2) % 16 ≠ 3 ∧ (a^2 + b^2) % 16 ≠ 7 ∧
    (a^2 + b^2) % 16 ≠ 11 ∧ (a^2 + b^2) % 16 ≠ 15 := by
  have sq : ∀ x : ℤ, x^2 % 16 = (x % 16)^2 % 16 := by
    intro x
    rw [sq, sq, Int.mul_emod, Int.mul_emod (x % 16), Int.emod_emod_of_dvd x (by norm_num)]
  have key : (a^2 + b^2) % 16 = ((a % 16)^2 + (b % 16)^2) % 16 := by
    rw [Int.add_emod, sq a, sq b, ← Int.add_emod]
  rw [key]
  have ha : 0 ≤ a % 16 ∧ a % 16 < 16 := ⟨Int.emod_nonneg a (by norm_num), Int.emod_lt_of_pos a (by norm_num)⟩
  have hb : 0 ≤ b % 16 ∧ b % 16 < 16 := ⟨Int.emod_nonneg b (by norm_num), Int.emod_lt_of_pos b (by norm_num)⟩
  obtain ⟨ha0, ha1⟩ := ha
  obtain ⟨hb0, hb1⟩ := hb
  interval_cases (a % 16) <;> interval_cases (b % 16) <;> decide