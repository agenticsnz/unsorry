import Mathlib

set_option maxRecDepth 8000 in
theorem dvd_sixteen_odd_pow_four_sub_one (n : ℤ) (hn : Odd n) : (16 : ℤ) ∣ n ^ 4 - 1 := by
  obtain ⟨k, rfl⟩ := hn
  obtain ⟨m, hm⟩ := Int.even_mul_succ_self k
  refine ⟨k ^ 4 + 2 * k ^ 3 + k ^ 2 + m, ?_⟩
  have hk : k ^ 2 + k = m + m := by nlinarith [hm]
  nlinarith [hk]